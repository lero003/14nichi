import Foundation
import SwiftData
import Testing
@testable import FourteenDayCore

@MainActor
@Suite("Stockpile persistence")
struct StockpilePersistenceTests {
    @Test("the first load creates one plan with the default checklist")
    func createsDefaultPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plan = try StockpileStore.loadOrCreatePlan(in: context)

        #expect(plan.stableID == StockpileStore.primaryPlanID)
        #expect(plan.adultCount == 1)
        #expect(plan.targetDays == .seven)
        #expect(plan.items.map(\.stableID).sorted() == [
            "drinking-water",
            "meals",
            "portable-toilet",
        ])
        #expect(plan.items.allSatisfy { $0.dailyAmountPerPerson == 0 })
        #expect(plan.items.allSatisfy { $0.expirationDate == nil })
    }

    @Test("loading again reuses the plan without duplicating checklist items")
    func reusesExistingPlan() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let first = try StockpileStore.loadOrCreatePlan(in: context)
        let second = try StockpileStore.loadOrCreatePlan(in: context)

        #expect(first.persistentModelID == second.persistentModelID)
        #expect(second.items.count == 3)
    }

    @Test("household quantities checklist state and expiration persist")
    func persistsChanges() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = try StockpileStore.loadOrCreatePlan(in: context)
        let item = try #require(plan.items.first { $0.stableID == "drinking-water" })
        let expiration = try #require(date(year: 2026, month: 12, day: 31))

        plan.adultCount = 2
        plan.childCount = 1
        plan.targetDays = .fourteen
        item.dailyAmountPerPerson = 1.5
        item.currentAmount = 8
        item.isPrepared = true
        item.expirationDate = expiration
        try StockpileStore.save(context)

        let verificationContext = ModelContext(container)
        let planID = StockpileStore.primaryPlanID
        let descriptor = FetchDescriptor<StockpileSchemaV1.Plan>(
            predicate: #Predicate { $0.stableID == planID }
        )
        let storedPlan = try #require(verificationContext.fetch(descriptor).first)
        let storedItem = try #require(storedPlan.items.first { $0.stableID == "drinking-water" })

        #expect(storedPlan.adultCount == 2)
        #expect(storedPlan.childCount == 1)
        #expect(storedPlan.targetDays == .fourteen)
        #expect(storedItem.dailyAmountPerPerson == 1.5)
        #expect(storedItem.currentAmount == 8)
        #expect(storedItem.isPrepared)
        #expect(storedItem.expirationDate == expiration)
    }

    @Test("missing default items are restored without resetting existing values")
    func restoresMissingDefaultItems() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let plan = StockpileSchemaV1.Plan(
            stableID: StockpileStore.primaryPlanID,
            adultCount: 4,
            targetDays: .fourteen
        )
        context.insert(plan)
        try context.save()

        let loaded = try StockpileStore.loadOrCreatePlan(in: context)

        #expect(loaded.adultCount == 4)
        #expect(loaded.targetDays == .fourteen)
        #expect(loaded.items.count == 3)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(StockpileSchemaV1.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: StockpileMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
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
