import Foundation

public enum StockpileTargetDays: Int, CaseIterable, Codable, Identifiable, Sendable {
    case seven = 7
    case fourteen = 14

    public var id: Int { rawValue }

    public var displayName: String {
        "\(rawValue)日"
    }
}

public struct HouseholdProfile: Codable, Equatable, Sendable {
    public let adultCount: Int
    public let childCount: Int
    public let seniorCount: Int

    public init(adultCount: Int, childCount: Int, seniorCount: Int) {
        self.adultCount = max(0, adultCount)
        self.childCount = max(0, childCount)
        self.seniorCount = max(0, seniorCount)
    }

    public var totalPeople: Int {
        adultCount + childCount + seniorCount
    }
}

public struct StockpileEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let unit: String
    public var dailyAmountPerPerson: Double
    public var currentAmount: Double

    public init(
        id: String,
        name: String,
        unit: String,
        dailyAmountPerPerson: Double = 0,
        currentAmount: Double = 0
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.dailyAmountPerPerson = dailyAmountPerPerson
        self.currentAmount = currentAmount
    }
}

public struct StockpileResult: Equatable, Identifiable, Sendable {
    public let entry: StockpileEntry
    public let householdPeople: Int
    public let targetDays: Int
    public let requiredAmount: Double
    public let currentAmount: Double
    public let shortageAmount: Double
    public let coveredDays: Double?

    public var id: StockpileEntry.ID { entry.id }

    public var isConfigured: Bool {
        householdPeople > 0 && entry.dailyAmountPerPerson.isFinite && entry.dailyAmountPerPerson > 0
    }

    public var hasShortage: Bool {
        isConfigured && shortageAmount > 0
    }
}

public enum StockpileCalculator {
    public static func calculate(
        entry: StockpileEntry,
        household: HouseholdProfile,
        targetDays: StockpileTargetDays
    ) -> StockpileResult {
        let dailyAmount = sanitized(entry.dailyAmountPerPerson)
        let currentAmount = sanitized(entry.currentAmount)
        let people = household.totalPeople
        let dailyHouseholdAmount = dailyAmount * Double(people)
        let requiredAmount = dailyHouseholdAmount * Double(targetDays.rawValue)
        let shortageAmount = max(requiredAmount - currentAmount, 0)
        let coveredDays = dailyHouseholdAmount > 0
            ? currentAmount / dailyHouseholdAmount
            : nil

        return StockpileResult(
            entry: entry,
            householdPeople: people,
            targetDays: targetDays.rawValue,
            requiredAmount: requiredAmount,
            currentAmount: currentAmount,
            shortageAmount: shortageAmount,
            coveredDays: coveredDays
        )
    }

    private static func sanitized(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return 0 }
        return value
    }
}

public enum StockpileShoppingList {
    public static func shortages(
        entries: [StockpileEntry],
        household: HouseholdProfile,
        targetDays: StockpileTargetDays
    ) -> [StockpileResult] {
        entries.compactMap { entry in
            let result = StockpileCalculator.calculate(
                entry: entry,
                household: household,
                targetDays: targetDays
            )
            return result.hasShortage ? result : nil
        }
    }
}
