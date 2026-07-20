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

/// 備蓄品目の種類。数量まで公的根拠があるものだけ `quantified` とする。
public enum StockpileItemKind: String, Equatable, Sendable {
    /// 1人1日あたりの数量目安を自動計算する。
    case quantified
    /// 数量は家庭差が大きいため、不足チェックのみ（買い物リストへ載せる）。
    case checklist
}

public struct StockpileRecommendation: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let unit: String
    public let kind: StockpileItemKind
    /// `quantified` のときだけ正の値。`checklist` は 0。
    public let dailyAmountPerPerson: Double
    public let example: String
    public let group: String
    public let source: StockpileGuidanceSource

    public init(
        id: String,
        name: String,
        unit: String,
        kind: StockpileItemKind,
        dailyAmountPerPerson: Double,
        example: String,
        group: String,
        source: StockpileGuidanceSource
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.kind = kind
        self.dailyAmountPerPerson = kind == .quantified ? max(0, dailyAmountPerPerson) : 0
        self.example = example
        self.group = group
        self.source = source
    }

    public var isQuantified: Bool {
        kind == .quantified && dailyAmountPerPerson > 0
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
    private static let caoCheckURL = URL(string: "https://www.bousai.go.jp/kyoiku/hokenkyousai/check.html")!
    private static let govPrepURL = URL(string: "https://www.gov-online.go.jp/tokusyu/bousai/preparation.html")!
    private static let kanteiSonaeURL = URL(string: "https://www.kantei.go.jp/jp/headline/bousai/sonae.html")!
    private static let tokyoToiletURL = URL(string: "https://www.bousai.metro.tokyo.lg.jp/_res/projects/default_project/_page_/001/030/489/toire.pdf")!
    private static let maffFoodURL = URL(string: "https://www.maff.go.jp/j/zyukyu/foodstock/")!

    private static let caoCheck = StockpileGuidanceSource(
        title: "自然災害への備えは万全ですか？チェックしてみよう！",
        publisher: "内閣府",
        url: caoCheckURL,
        accessedAt: "2026-07-20",
        rightsNote: "公的な備蓄の考え方を自前の表現で示す。原文は転載しない。"
    )

    private static let govPrep = StockpileGuidanceSource(
        title: "防災特集 ACTION01 災害に事前に備える",
        publisher: "政府広報オンライン",
        url: govPrepURL,
        accessedAt: "2026-07-20",
        rightsNote: "家庭備蓄・生活インフラ代替の例示を自前の言葉で案内する。数量の内訳は自動配分しない。"
    )

    private static let kanteiSonae = StockpileGuidanceSource(
        title: "災害が起きる前にできること",
        publisher: "首相官邸",
        url: kanteiSonaeURL,
        accessedAt: "2026-07-20",
        rightsNote: "非常持ち出し・生活用品の例示を自前の表現で示す。家庭差があるため数量は自動計算しない。"
    )

    private static let tokyoToilet = StockpileGuidanceSource(
        title: "災害時、トイレには駆け込めないかも！災害に備えて",
        publisher: "東京都総務局総合防災部",
        url: tokyoToiletURL,
        accessedAt: "2026-07-20",
        rightsNote: "1人1日平均5回という公的な想定だけを自前の表現で表示する。"
    )

    private static let maffFood = StockpileGuidanceSource(
        title: "災害時に備えた食品ストックガイド",
        publisher: "農林水産省",
        url: maffFoodURL,
        accessedAt: "2026-07-20",
        rightsNote: "食品備蓄の公的な考え方への参照。品目別の個数配分は行わない。"
    )

    public static let all: [StockpileRecommendation] = [
        // MARK: 数量の目安（公的に1人1日が示されているもの）
        StockpileRecommendation(
            id: "drinking-water",
            name: "飲料水",
            unit: "L",
            kind: .quantified,
            dailyAmountPerPerson: 3,
            example: "飲用と調理に使う水。ペットボトルのローリングストックも有効",
            group: "数量の目安",
            source: caoCheck
        ),
        StockpileRecommendation(
            id: "meals",
            name: "食料",
            unit: "食分",
            kind: .quantified,
            dailyAmountPerPerson: 3,
            example: "普段食べる保存食品、缶詰、レトルト、乾パンなど。内訳個数は家庭で調整",
            group: "数量の目安",
            source: govPrep
        ),
        StockpileRecommendation(
            id: "portable-toilet",
            name: "携帯トイレ",
            unit: "回分",
            kind: .quantified,
            dailyAmountPerPerson: 5,
            example: "便器に取り付ける凝固剤・袋のセットなど",
            group: "数量の目安",
            source: tokyoToilet
        ),

        // MARK: 水・衛生
        checklist(
            id: "toilet-paper",
            name: "トイレットペーパー",
            example: "ロールと、断水時用のティッシュ・ウェットティッシュ",
            group: "水・衛生",
            source: kanteiSonae
        ),
        checklist(
            id: "trash-bags",
            name: "ゴミ袋・ポリ袋",
            example: "排泄物・生ゴミの密閉、給水、分別に使える厚手の袋",
            group: "水・衛生",
            source: govPrep
        ),
        checklist(
            id: "wet-wipes",
            name: "ウェットティッシュ・清拭用品",
            example: "手洗いが難しいときの手指・身体の清拭",
            group: "水・衛生",
            source: kanteiSonae
        ),
        checklist(
            id: "sanitary-products",
            name: "生理用品",
            example: "普段の使用量より多め。配布が遅れやすい品目として意識する",
            group: "水・衛生",
            source: govPrep
        ),
        checklist(
            id: "water-jugs",
            name: "給水袋・ポリタンク",
            example: "給水所からの運搬用。折りたたみ式やペットボトルも可",
            group: "水・衛生",
            source: caoCheck
        ),
        checklist(
            id: "plastic-wrap",
            name: "ラップ・アルミホイル",
            example: "食器を汚さない、食品の簡易保存、応急の保温など",
            group: "水・衛生",
            source: kanteiSonae
        ),

        // MARK: 調理・食料まわり
        checklist(
            id: "cassette-stove",
            name: "カセットコンロ",
            example: "電気・都市ガスが止まったときの簡易調理・お湯沸かし",
            group: "調理・食料",
            source: govPrep
        ),
        checklist(
            id: "cassette-gas",
            name: "カセットボンベ",
            example: "コンロ用の予備。使用時の換気と火気に注意",
            group: "調理・食料",
            source: govPrep
        ),
        checklist(
            id: "can-opener",
            name: "缶切り・多機能ツール",
            example: "プルトップでない缶詰に対応できるもの",
            group: "調理・食料",
            source: maffFood
        ),
        checklist(
            id: "disposable-tableware",
            name: "紙皿・割り箸・使い捨て食器",
            example: "洗い水を節約するための簡易食器",
            group: "調理・食料",
            source: maffFood
        ),

        // MARK: 電源・照明・情報
        checklist(
            id: "flashlight",
            name: "懐中電灯・ランタン",
            example: "手元用ライトと、部屋全体を照らすランタンの両方があると便利",
            group: "電源・照明",
            source: kanteiSonae
        ),
        checklist(
            id: "batteries",
            name: "乾電池",
            example: "ライト・ラジオ用。サイズを揃えて多めに",
            group: "電源・照明",
            source: kanteiSonae
        ),
        checklist(
            id: "power-bank",
            name: "モバイルバッテリー",
            example: "スマートフォン用。満充電を維持し、期限や劣化に注意",
            group: "電源・照明",
            source: govPrep
        ),
        checklist(
            id: "radio",
            name: "携帯ラジオ",
            example: "手回し・電池式など、通信障害時の情報取得用",
            group: "電源・照明",
            source: kanteiSonae
        ),

        // MARK: 非常持ち出し・安全
        checklist(
            id: "first-aid-kit",
            name: "救急セット",
            example: "絆創膏、包帯、消毒液、解熱鎮痛剤など家庭で使い慣れたもの",
            group: "持ち出し・安全",
            source: caoCheck
        ),
        checklist(
            id: "medications",
            name: "常用薬・お薬手帳の写し",
            example: "数日〜1週間分を目安に。処方薬はかかりつけ医の指示に従う",
            group: "持ち出し・安全",
            source: kanteiSonae
        ),
        checklist(
            id: "cash-small-bills",
            name: "現金（少額紙幣・硬貨）",
            example: "決済や自動販売機が使えないときの少額現金",
            group: "持ち出し・安全",
            source: kanteiSonae
        ),
        checklist(
            id: "whistle",
            name: "笛",
            example: "閉じ込められたときの合図用",
            group: "持ち出し・安全",
            source: caoCheck
        ),
        checklist(
            id: "work-gloves",
            name: "軍手・作業用手袋",
            example: "がれきやガラスの扱い、荷物の運搬",
            group: "持ち出し・安全",
            source: caoCheck
        ),
        checklist(
            id: "rain-gear",
            name: "雨具・防寒具",
            example: "レインコート、毛布、カイロなど季節に合わせたもの",
            group: "持ち出し・安全",
            source: kanteiSonae
        ),
        checklist(
            id: "masks",
            name: "マスク",
            example: "ほこり・飛沫対策。多めにあると安心",
            group: "持ち出し・安全",
            source: govPrep
        ),
        checklist(
            id: "id-copies",
            name: "身分証・保険証の写し",
            example: "原本と別にコピーや写真を保管（暗証番号は書かない）",
            group: "持ち出し・安全",
            source: kanteiSonae
        ),
    ]

    public static func recommendation(id: String) -> StockpileRecommendation? {
        all.first { $0.id == id }
    }

    public static var groups: [String] {
        var seen = Set<String>()
        return all.compactMap { item in
            guard seen.insert(item.group).inserted else { return nil }
            return item.group
        }
    }

    private static func checklist(
        id: String,
        name: String,
        example: String,
        group: String,
        source: StockpileGuidanceSource
    ) -> StockpileRecommendation {
        StockpileRecommendation(
            id: id,
            name: name,
            unit: "式",
            kind: .checklist,
            dailyAmountPerPerson: 0,
            example: example,
            group: group,
            source: source
        )
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
