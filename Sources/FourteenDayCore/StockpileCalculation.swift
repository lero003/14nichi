import Foundation

public enum StockpileTargetDays: Int, CaseIterable, Codable, Identifiable, Sendable {
    case seven = 7
    case fourteen = 14

    public var id: Int { rawValue }

    public var displayName: String {
        "\(rawValue)日"
    }
}

public struct StockpileGuidanceSource: Equatable, Sendable {
    public let title: String
    public let publisher: String
    public let url: URL
    public let accessedAt: String
    public let usage: String
    public let rightsNote: String

    public init(
        title: String,
        publisher: String,
        url: URL,
        accessedAt: String,
        usage: String = "paraphrase",
        rightsNote: String
    ) {
        self.title = title
        self.publisher = publisher
        self.url = url
        self.accessedAt = accessedAt
        self.usage = usage
        self.rightsNote = rightsNote
    }
}

public struct StockpileRecommendation: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let unit: String
    public let dailyAmountPerPerson: Double
    public let example: String
    public let source: StockpileGuidanceSource

    public init(
        id: String,
        name: String,
        unit: String,
        dailyAmountPerPerson: Double,
        example: String,
        source: StockpileGuidanceSource
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.dailyAmountPerPerson = dailyAmountPerPerson
        self.example = example
        self.source = source
    }

    public func entry() -> StockpileEntry {
        StockpileEntry(
            id: id,
            name: name,
            unit: unit,
            dailyAmountPerPerson: dailyAmountPerPerson
        )
    }
}

public enum StockpileRecommendations {
    public static let all: [StockpileRecommendation] = [
        StockpileRecommendation(
            id: "drinking-water",
            name: "飲料水",
            unit: "L",
            dailyAmountPerPerson: 3,
            example: "飲用と調理に使う水",
            source: StockpileGuidanceSource(
                title: "自然災害への備えは万全ですか？チェックしてみよう！",
                publisher: "内閣府",
                url: URL(string: "https://www.bousai.go.jp/kyoiku/hokenkyousai/check.html")!,
                accessedAt: "2026-07-20",
                rightsNote: "1人1日3Lという公的な目安だけを自前の表現で表示する。"
            )
        ),
        StockpileRecommendation(
            id: "meals",
            name: "食料",
            unit: "食分",
            dailyAmountPerPerson: 3,
            example: "普段食べる保存食品、缶詰、レトルト、乾パンなど",
            source: StockpileGuidanceSource(
                title: "防災特集 ACTION01 災害に事前に備える",
                publisher: "政府広報オンライン",
                url: URL(string: "https://www.gov-online.go.jp/tokusyu/bousai/preparation.html")!,
                accessedAt: "2026-07-20",
                rightsNote: "1人1日3食という公的な目安だけを自前の表現で表示する。"
            )
        ),
        StockpileRecommendation(
            id: "portable-toilet",
            name: "携帯トイレ",
            unit: "回分",
            dailyAmountPerPerson: 5,
            example: "便器に取り付ける凝固剤・袋のセットなど",
            source: StockpileGuidanceSource(
                title: "災害時、トイレには駆け込めないかも！災害に備えて",
                publisher: "東京都総務局総合防災部",
                url: URL(string: "https://www.bousai.metro.tokyo.lg.jp/_res/projects/default_project/_page_/001/030/489/toire.pdf")!,
                accessedAt: "2026-07-20",
                rightsNote: "1人1日平均5回という公的な想定だけを自前の表現で表示する。"
            )
        ),
    ]

    public static func recommendation(id: String) -> StockpileRecommendation? {
        all.first { $0.id == id }
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
