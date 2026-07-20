import Foundation
import SwiftData
import Testing
@testable import FourteenDayCore

@MainActor
@Suite("Stockpile persistence")
struct StockpilePersistenceTests {
    @Test("the first load creates the simplified recommendation checklist")
    func createsDefaultPlan() throws {
        let container = try makeContainer()
        let plan = try StockpileStore.loadOrCreatePlan(in: container.mainContext)

        #expect(plan.stableID == StockpileStore.primaryPlanID)
        #expect(plan.household.totalPeople == 1)
        #expect(plan.targetDays == .seven)
        #expect(plan.items.map(\.stableID).sorted() == StockpileRecommendations.all.map(\.id).sorted())
        #expect(plan.items.count == StockpileRecommendations.all.count)
        #expect(plan.items.allSatisfy { !$0.isShortage && !$0.isPurchased })
        #expect(StockpileRecommendations.all.contains { $0.isQuantified })
        #expect(StockpileRecommendations.all.contains { $0.kind == .checklist })
    }

    @Test("loading again reuses the plan without duplicating checklist items")
    func reusesExistingPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let first = try StockpileStore.loadOrCreatePlan(in: context)
        let second = try StockpileStore.loadOrCreatePlan(in: context)

        #expect(first.persistentModelID == second.persistentModelID)
        #expect(second.items.count == StockpileRecommendations.all.count)
    }

    @Test("people period shortage selection and purchase state persist")
    func persistsSimplifiedFlow() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = try StockpileStore.loadOrCreatePlan(in: context)
        let water = try #require(plan.items.first { $0.stableID == "drinking-water" })

        plan.adultCount = 3
        plan.childCount = 0
        plan.seniorCount = 0
        plan.targetDays = .fourteen
        water.isShortage = true
        try StockpileStore.save(context)
        try StockpileStore.markPurchased(water, in: context)

        let verificationContext = ModelContext(container)
        let planID = StockpileStore.primaryPlanID
        let descriptor = FetchDescriptor<StockpileSchema.Plan>(
            predicate: #Predicate { $0.stableID == planID }
        )
        let storedPlan = try #require(verificationContext.fetch(descriptor).first)
        let storedWater = try #require(storedPlan.items.first { $0.stableID == "drinking-water" })

        #expect(storedPlan.household.totalPeople == 3)
        #expect(storedPlan.targetDays == .fourteen)
        #expect(storedWater.isShortage)
        #expect(storedWater.isPurchased)
    }

    @Test("missing default items are restored without resetting the plan")
    func restoresMissingDefaultItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = StockpileSchema.Plan(
            stableID: StockpileStore.primaryPlanID,
            adultCount: 4,
            targetDays: .fourteen
        )
        context.insert(plan)
        try context.save()

        let loaded = try StockpileStore.loadOrCreatePlan(in: context)

        #expect(loaded.household.totalPeople == 4)
        #expect(loaded.targetDays == .fourteen)
        #expect(loaded.items.count == StockpileRecommendations.all.count)
    }

    @Test("legacy detailed input becomes a one-time shortage selection")
    func upgradesLegacyState() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = StockpileSchema.Plan(
            stableID: StockpileStore.primaryPlanID,
            adultCount: 2,
            targetDays: .seven,
            simplifiedFlowVersion: nil
        )
        let water = StockpileSchema.Item(
            stableID: "drinking-water",
            name: "飲料水",
            unit: "L",
            sortOrder: 0,
            dailyAmountPerPerson: 3,
            currentAmount: 10,
            plan: plan
        )
        context.insert(plan)
        context.insert(water)
        plan.items.append(water)
        try context.save()

        let loaded = try StockpileStore.loadOrCreatePlan(in: context)
        let loadedWater = try #require(loaded.items.first { $0.stableID == "drinking-water" })

        #expect(loaded.simplifiedFlowVersion == 1)
        #expect(loadedWater.isShortage)
        #expect(!loadedWater.isPurchased)
    }

    @Test("a persisted V1 store opens through the V2 migration plan")
    func migratesPersistedV1Store() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StockpileMigrationTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = directory.appendingPathComponent("stockpile.store")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            let schema = Schema(StockpileSchemaV1.models)
            let configuration = ModelConfiguration(
                "StockpileV1",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let plan = StockpileSchemaV1.Plan(
                stableID: StockpileStore.primaryPlanID,
                adultCount: 2,
                targetDays: .seven
            )
            let water = StockpileSchemaV1.Item(
                stableID: "drinking-water",
                name: "飲料水",
                unit: "L",
                sortOrder: 0,
                dailyAmountPerPerson: 3,
                currentAmount: 10,
                plan: plan
            )
            container.mainContext.insert(plan)
            container.mainContext.insert(water)
            plan.items.append(water)
            try container.mainContext.save()
        }

        do {
            let schema = Schema(StockpileSchema.models)
            let configuration = ModelConfiguration(
                "StockpileV2",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StockpileMigrationPlan.self,
                configurations: [configuration]
            )
            let plan = try StockpileStore.loadOrCreatePlan(in: container.mainContext)
            let water = try #require(plan.items.first { $0.stableID == "drinking-water" })

            #expect(plan.household.totalPeople == 2)
            #expect(plan.simplifiedFlowVersion == 1)
            #expect(water.isShortage)
        }
    }

    @Test("purchase action ignores an item that was not selected as short")
    func skipsUnselectedItem() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = try StockpileStore.loadOrCreatePlan(in: context)
        let food = try #require(plan.items.first { $0.stableID == "meals" })

        try StockpileStore.markPurchased(food, in: context)

        #expect(!food.isPurchased)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(StockpileSchema.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: schema,
            migrationPlan: StockpileMigrationPlan.self,
            configurations: [configuration]
        )
    }
}

@Suite("Stockpile recommendation rules")
struct StockpileRecommendationTests {
    @Test("official baseline rates produce a seven-day one-person overview")
    func calculatesBaseline() throws {
        let household = HouseholdProfile(adultCount: 1, childCount: 0, seniorCount: 0)
        let results = StockpileRecommendations.all.map {
            StockpileCalculator.calculate(entry: $0.entry(), household: household, targetDays: .seven)
        }

        #expect(results.first { $0.id == "drinking-water" }?.requiredAmount == 21)
        #expect(results.first { $0.id == "meals" }?.requiredAmount == 21)
        #expect(results.first { $0.id == "portable-toilet" }?.requiredAmount == 35)
    }

    @Test("every recommendation has complete https source metadata")
    func validatesSourceMetadata() {
        for recommendation in StockpileRecommendations.all {
            #expect(recommendation.source.url.scheme == "https")
            #expect(!recommendation.source.publisher.isEmpty)
            #expect(!recommendation.source.accessedAt.isEmpty)
            #expect(!recommendation.source.usage.isEmpty)
            #expect(!recommendation.source.rightsNote.isEmpty)
            #expect(!recommendation.group.isEmpty)
        }
    }

    @Test("checklist items never produce auto-calculated quantities")
    func checklistItemsAreNotQuantified() {
        let household = HouseholdProfile(adultCount: 2, childCount: 0, seniorCount: 0)
        for recommendation in StockpileRecommendations.all where recommendation.kind == .checklist {
            #expect(recommendation.isQuantified == false)
            let result = StockpileCalculator.calculate(
                entry: recommendation.entry(),
                household: household,
                targetDays: .fourteen
            )
            #expect(result.isConfigured == false)
            #expect(result.requiredAmount == 0)
        }
    }
}

@Suite("Stockpile expiration status")
struct StockpileExpirationStatusTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("missing expiration stays unclassified")
    func missingExpiration() {
        #expect(StockpileExpirationStatus.evaluate(expirationDate: nil) == .none)
    }

    @Test(
        "expiration status uses calendar-day boundaries",
        arguments: [
            ExpirationFixture(offset: -2, expected: .expired(daysAgo: 2)),
            ExpirationFixture(offset: 0, expected: .dueSoon(daysRemaining: 0)),
            ExpirationFixture(offset: 30, expected: .dueSoon(daysRemaining: 30)),
            ExpirationFixture(offset: 31, expected: .scheduled(daysRemaining: 31)),
        ]
    )
    func evaluatesBoundary(_ fixture: ExpirationFixture) throws {
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 20)))
        let expiration = try #require(calendar.date(byAdding: .day, value: fixture.offset, to: today))

        let status = StockpileExpirationStatus.evaluate(
            expirationDate: expiration,
            today: today,
            calendar: calendar
        )

        #expect(status == fixture.expected)
    }
}

struct ExpirationFixture: Sendable {
    let offset: Int
    let expected: StockpileExpirationStatus
}
