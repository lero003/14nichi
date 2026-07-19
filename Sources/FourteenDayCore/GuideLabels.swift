import Foundation

public extension GuideArticle.Priority {
    /// Smaller values appear first in lists.
    var sortIndex: Int {
        switch self {
        case .critical: 0
        case .high: 1
        case .normal: 2
        }
    }

    var displayName: String {
        switch self {
        case .critical: "最優先"
        case .high: "優先"
        case .normal: "通常"
        }
    }
}

public extension GuideArticle.ReviewStatus {
    var displayName: String {
        switch self {
        case .draft: "制作確認用"
        case .reviewed: "校正済み"
        case .approved: "監修済み"
        }
    }

    var isProductReady: Bool {
        self == .approved
    }
}

public enum GuidePeriod: String, CaseIterable, Sendable {
    case immediate
    case day1
    case day3
    case day7
    case day14

    public var displayName: String {
        switch self {
        case .immediate: "いま"
        case .day1: "初日"
        case .day3: "3日"
        case .day7: "7日"
        case .day14: "14日"
        }
    }

    public var sortIndex: Int {
        switch self {
        case .immediate: 0
        case .day1: 1
        case .day3: 2
        case .day7: 3
        case .day14: 4
        }
    }
}

public extension GuideArticle {
    var periodLabels: [String] {
        periods.compactMap { raw in
            GuidePeriod(rawValue: raw)?.displayName
        }
    }

    var isDraftFixture: Bool {
        !reviewStatus.isProductReady
    }
}

public extension GuideArticle.Source.Usage {
    var displayName: String {
        switch self {
        case .linkOnly: "参照リンク"
        case .paraphrase: "要約・言い換え"
        case .shortQuote: "短文引用"
        }
    }
}

public extension GuideArticle.Source {
    var hasExcerpt: Bool {
        guard let excerpt else { return false }
        return !excerpt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
