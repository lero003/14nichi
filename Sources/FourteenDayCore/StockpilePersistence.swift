import Foundation
import SwiftData

public enum StockpileSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Plan.self, Item.self]
    }

    @Model
    public final class Plan {
        #Unique<Plan>([\.stableID])

        public var stableID: String
        public var adultCount: Int
        public var childCount: Int
        public var seniorCount: Int
        public var targetDaysRawValue: Int

        @Relationship(deleteRule: .cascade, inverse: \Item.plan)
        public var items: [Item]

        public init(
            stableID: String,
            adultCount: Int = 1,
            childCount: Int = 0,
            seniorCount: Int = 0,
            targetDays: StockpileTargetDays = .seven,
            items: [Item] = []
        ) {
            self.stableID = stableID
            self.adultCount = max(0, adultCount)
            self.childCount = max(0, childCount)
            self.seniorCount = max(0, seniorCount)
            self.targetDaysRawValue = targetDays.rawValue
            self.items = items
        }

        public var targetDays: StockpileTargetDays {
            get { StockpileTargetDays(rawValue: targetDaysRawValue) ?? .seven }
            set { targetDaysRawValue = newValue.rawValue }
        }

        public var household: HouseholdProfile {
            HouseholdProfile(
                adultCount: adultCount,
                childCount: childCount,
                seniorCount: seniorCount
            )
        }
    }

    @Model
    public final class Item {
        #Unique<Item>([\.stableID])
        #Index<Item>([\.sortOrder], [\.expirationDate])

        public var stableID: String
        public var name: String
        public var unit: String
        public var sortOrder: Int
        public var dailyAmountPerPerson: Double
        public var currentAmount: Double
        public var isPrepared: Bool
        public var expirationDate: Date?
        public var plan: Plan?

        public init(
            stableID: String,
            name: String,
            unit: String,
            sortOrder: Int,
            dailyAmountPerPerson: Double = 0,
            currentAmount: Double = 0,
            isPrepared: Bool = false,
            expirationDate: Date? = nil,
            plan: Plan? = nil
        ) {
            self.stableID = stableID
            self.name = name
            self.unit = unit
            self.sortOrder = sortOrder
            self.dailyAmountPerPerson = Self.sanitized(dailyAmountPerPerson)
            self.currentAmount = Self.sanitized(currentAmount)
            self.isPrepared = isPrepared
            self.expirationDate = expirationDate
            self.plan = plan
        }

        public var calculationEntry: StockpileEntry {
            StockpileEntry(
                id: stableID,
                name: name,
                unit: unit,
                dailyAmountPerPerson: dailyAmountPerPerson,
                currentAmount: currentAmount
            )
        }

        private static func sanitized(_ value: Double) -> Double {
            guard value.isFinite, value > 0 else { return 0 }
            return value
        }
    }
}

public enum StockpileSchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Plan.self, Item.self]
    }

    @Model
    public final class Plan {
        #Unique<Plan>([\.stableID])

        public var stableID: String
        public var adultCount: Int
        public var childCount: Int
        public var seniorCount: Int
        public var targetDaysRawValue: Int
        public var simplifiedFlowVersion: Int?

        @Relationship(deleteRule: .cascade, inverse: \Item.plan)
        public var items: [Item]

        public init(
            stableID: String,
            adultCount: Int = 1,
            childCount: Int = 0,
            seniorCount: Int = 0,
            targetDays: StockpileTargetDays = .seven,
            simplifiedFlowVersion: Int? = 1,
            items: [Item] = []
        ) {
            self.stableID = stableID
            self.adultCount = max(0, adultCount)
            self.childCount = max(0, childCount)
            self.seniorCount = max(0, seniorCount)
            self.targetDaysRawValue = targetDays.rawValue
            self.simplifiedFlowVersion = simplifiedFlowVersion
            self.items = items
        }

        public var targetDays: StockpileTargetDays {
            get { StockpileTargetDays(rawValue: targetDaysRawValue) ?? .seven }
            set { targetDaysRawValue = newValue.rawValue }
        }

        public var household: HouseholdProfile {
            HouseholdProfile(
                adultCount: adultCount,
                childCount: childCount,
                seniorCount: seniorCount
            )
        }
    }

    @Model
    public final class Item {
        #Unique<Item>([\.stableID])
        #Index<Item>([\.sortOrder], [\.expirationDate])

        public var stableID: String
        public var name: String
        public var unit: String
        public var sortOrder: Int
        public var dailyAmountPerPerson: Double
        public var currentAmount: Double
        public var isPrepared: Bool
        public var expirationDate: Date?
        public var isShortage: Bool = false
        public var isPurchased: Bool = false
        public var plan: Plan?

        public init(
            stableID: String,
            name: String,
            unit: String,
            sortOrder: Int,
            dailyAmountPerPerson: Double = 0,
            currentAmount: Double = 0,
            isPrepared: Bool = false,
            expirationDate: Date? = nil,
            isShortage: Bool = false,
            isPurchased: Bool = false,
            plan: Plan? = nil
        ) {
            self.stableID = stableID
            self.name = name
            self.unit = unit
            self.sortOrder = sortOrder
            self.dailyAmountPerPerson = Self.sanitized(dailyAmountPerPerson)
            self.currentAmount = Self.sanitized(currentAmount)
            self.isPrepared = isPrepared
            self.expirationDate = expirationDate
            self.isShortage = isShortage
            self.isPurchased = isPurchased
            self.plan = plan
        }

        public var calculationEntry: StockpileEntry {
            if let recommendation = StockpileRecommendations.recommendation(id: stableID) {
                return recommendation.entry()
            }
            return StockpileEntry(
                id: stableID,
                name: name,
                unit: unit,
                dailyAmountPerPerson: dailyAmountPerPerson
            )
        }

        private static func sanitized(_ value: Double) -> Double {
            guard value.isFinite, value > 0 else { return 0 }
            return value
        }
    }
}

public typealias StockpileSchema = StockpileSchemaV2

public enum StockpileMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [StockpileSchemaV1.self, StockpileSchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: StockpileSchemaV1.self,
                toVersion: StockpileSchemaV2.self
            ),
        ]
    }
}

@MainActor
public enum StockpileStore {
    public static let primaryPlanID = "primary-stockpile-plan"

    @discardableResult
    public static func loadOrCreatePlan(in context: ModelContext) throws -> StockpileSchema.Plan {
        let planID = primaryPlanID
        var descriptor = FetchDescriptor<StockpileSchema.Plan>(
            predicate: #Predicate { $0.stableID == planID }
        )
        descriptor.fetchLimit = 1

        if let plan = try context.fetch(descriptor).first {
            try addMissingDefaultItems(to: plan, in: context)
            try upgradeLegacyStateIfNeeded(plan, in: context)
            return plan
        }

        let plan = StockpileSchema.Plan(stableID: planID)
        context.insert(plan)
        try addMissingDefaultItems(to: plan, in: context)
        return plan
    }

    public static func save(_ context: ModelContext) throws {
        try context.save()
    }

    public static func markPurchased(
        _ item: StockpileSchema.Item,
        in context: ModelContext
    ) throws {
        guard item.isShortage else { return }
        item.isPurchased = true
        try context.save()
    }

    private static func addMissingDefaultItems(
        to plan: StockpileSchema.Plan,
        in context: ModelContext
    ) throws {
        let existingIDs = Set(plan.items.map(\.stableID))

        for template in defaultItems where existingIDs.contains(template.stableID) == false {
            let item = StockpileSchema.Item(
                stableID: template.stableID,
                name: template.name,
                unit: template.unit,
                sortOrder: template.sortOrder,
                plan: plan
            )
            context.insert(item)
            plan.items.append(item)
        }

        try context.save()
    }

    private static func upgradeLegacyStateIfNeeded(
        _ plan: StockpileSchema.Plan,
        in context: ModelContext
    ) throws {
        guard plan.simplifiedFlowVersion == nil else { return }

        for item in plan.items {
            let legacyResult = StockpileCalculator.calculate(
                entry: StockpileEntry(
                    id: item.stableID,
                    name: item.name,
                    unit: item.unit,
                    dailyAmountPerPerson: item.dailyAmountPerPerson,
                    currentAmount: item.currentAmount
                ),
                household: plan.household,
                targetDays: plan.targetDays
            )
            item.isShortage = legacyResult.hasShortage
            item.isPurchased = item.isPrepared
        }
        plan.simplifiedFlowVersion = 1
        try context.save()
    }

    private static let defaultItems: [(stableID: String, name: String, unit: String, sortOrder: Int)] =
        StockpileRecommendations.all.enumerated().map { index, recommendation in
            (recommendation.id, recommendation.name, recommendation.unit, index)
        }
}

public enum StockpileExpirationStatus: Equatable, Sendable {
    case none
    case expired(daysAgo: Int)
    case dueSoon(daysRemaining: Int)
    case scheduled(daysRemaining: Int)

    public static func evaluate(
        expirationDate: Date?,
        today: Date = .now,
        calendar: Calendar = .current,
        soonThresholdDays: Int = 30
    ) -> Self {
        guard let expirationDate else { return .none }

        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: expirationDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days < 0 {
            return .expired(daysAgo: abs(days))
        }
        if days <= max(0, soonThresholdDays) {
            return .dueSoon(daysRemaining: days)
        }
        return .scheduled(daysRemaining: days)
    }
}
