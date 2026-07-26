import Foundation

public enum EmergencyCardPreparationChoice: String, Equatable, Sendable {
    case notReviewed
    case prepared
    case skipped

    public var isReviewed: Bool {
        self != .notReviewed
    }

    public static func afterSavingCard(hasContent: Bool) -> Self {
        hasContent ? .prepared : .notReviewed
    }
}

public struct PreparednessChecklistState: Equatable, Sendable {
    public var householdReviewedAt: Date?
    public var stockpileReviewedAt: Date?
    public var emergencyCardChoice: EmergencyCardPreparationChoice

    public init(
        householdReviewedAt: Date? = nil,
        stockpileReviewedAt: Date? = nil,
        emergencyCardChoice: EmergencyCardPreparationChoice = .notReviewed
    ) {
        self.householdReviewedAt = householdReviewedAt
        self.stockpileReviewedAt = stockpileReviewedAt
        self.emergencyCardChoice = emergencyCardChoice
    }

    public var reviewedCount: Int {
        (householdReviewedAt == nil ? 0 : 1)
            + (stockpileReviewedAt == nil ? 0 : 1)
            + (emergencyCardChoice.isReviewed ? 1 : 0)
    }
}

/// 個人情報を持たず、「準備項目を確認した」という事実だけを保存する。
public struct PreparednessChecklistStore: @unchecked Sendable {
    public static let defaultKeyPrefix = "preparednessChecklist.v1"

    private enum Key {
        static let householdReviewedAt = "householdReviewedAt"
        static let stockpileReviewedAt = "stockpileReviewedAt"
        static let emergencyCardChoice = "emergencyCardChoice"
    }

    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = Self.defaultKeyPrefix
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    public func load() -> PreparednessChecklistState {
        PreparednessChecklistState(
            householdReviewedAt: date(for: Key.householdReviewedAt),
            stockpileReviewedAt: date(for: Key.stockpileReviewedAt),
            emergencyCardChoice: defaults.string(forKey: key(Key.emergencyCardChoice))
                .flatMap(EmergencyCardPreparationChoice.init(rawValue:))
                ?? .notReviewed
        )
    }

    @discardableResult
    public func markHouseholdReviewed(at date: Date = .now) -> PreparednessChecklistState {
        defaults.set(date, forKey: key(Key.householdReviewedAt))
        return load()
    }

    @discardableResult
    public func markStockpileReviewed(at date: Date = .now) -> PreparednessChecklistState {
        defaults.set(date, forKey: key(Key.stockpileReviewedAt))
        return load()
    }

    @discardableResult
    public func setEmergencyCardChoice(
        _ choice: EmergencyCardPreparationChoice
    ) -> PreparednessChecklistState {
        defaults.set(choice.rawValue, forKey: key(Key.emergencyCardChoice))
        return load()
    }

    private func date(for suffix: String) -> Date? {
        defaults.object(forKey: key(suffix)) as? Date
    }

    private func key(_ suffix: String) -> String {
        "\(keyPrefix).\(suffix)"
    }
}
