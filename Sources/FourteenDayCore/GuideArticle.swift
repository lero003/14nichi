import Foundation

public struct GuideArticle: Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let path: String
    public let category: String
    public let priority: Priority
    public let situations: [String]
    public let periods: [String]
    public let region: String
    public let reviewStatus: ReviewStatus
    public let reviewedAt: String?
    public let reviewedBy: String?
    public let sources: [Source]
    public let bodyMarkdown: String

    public enum Priority: String, Codable, Sendable {
        case critical
        case high
        case normal
    }

    public enum ReviewStatus: String, Codable, Sendable {
        case draft
        case reviewed
        case approved
    }

    /// 記事が参照する一次情報。本文の権利処理と追跡可能性の単位。
    public struct Source: Codable, Hashable, Identifiable, Sendable {
        public let id: String
        public let title: String
        public let publisher: String
        public let url: URL
        /// 最終確認日（`YYYY-MM-DD`）。
        public let accessedAt: String
        public let usage: Usage
        /// 利用許諾・転載可否・要約方針などの短い権利注記。
        public let rightsNote: String
        /// `shortQuote` のときだけ。短文引用の本文。
        public let excerpt: String?

        public enum Usage: String, Codable, Sendable {
            /// 公式ページ等へのリンクのみ。本文は転載しない。
            case linkOnly
            /// 公的情報を踏まえた自前の言い換え・要約。原文の長い転載はしない。
            case paraphrase
            /// 必要な最小限の短文引用。`excerpt` 必須。
            case shortQuote
        }

        public init(
            id: String,
            title: String,
            publisher: String,
            url: URL,
            accessedAt: String,
            usage: Usage,
            rightsNote: String,
            excerpt: String? = nil
        ) {
            self.id = id
            self.title = title
            self.publisher = publisher
            self.url = url
            self.accessedAt = accessedAt
            self.usage = usage
            self.rightsNote = rightsNote
            self.excerpt = excerpt
        }
    }

    public init(metadata: Metadata, bodyMarkdown: String) {
        id = metadata.id
        title = metadata.title
        summary = metadata.summary
        path = metadata.path
        category = metadata.category
        priority = metadata.priority
        situations = metadata.situations
        periods = metadata.periods
        region = metadata.region
        reviewStatus = metadata.reviewStatus
        reviewedAt = metadata.reviewedAt
        reviewedBy = metadata.reviewedBy
        sources = metadata.sources
        self.bodyMarkdown = bodyMarkdown
    }

    public struct Metadata: Codable, Sendable {
        public let id: String
        public let title: String
        public let summary: String
        public let path: String
        public let category: String
        public let priority: Priority
        public let situations: [String]
        public let periods: [String]
        public let region: String
        public let reviewStatus: ReviewStatus
        public let reviewedAt: String?
        public let reviewedBy: String?
        public let sources: [Source]

        public init(
            id: String,
            title: String,
            summary: String,
            path: String,
            category: String,
            priority: Priority,
            situations: [String],
            periods: [String],
            region: String,
            reviewStatus: ReviewStatus,
            reviewedAt: String?,
            reviewedBy: String?,
            sources: [Source]
        ) {
            self.id = id
            self.title = title
            self.summary = summary
            self.path = path
            self.category = category
            self.priority = priority
            self.situations = situations
            self.periods = periods
            self.region = region
            self.reviewStatus = reviewStatus
            self.reviewedAt = reviewedAt
            self.reviewedBy = reviewedBy
            self.sources = sources
        }
    }
}

public struct GuideSituation: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let systemImage: String
    public let sortOrder: Int

    public init(
        id: String,
        title: String,
        summary: String,
        systemImage: String,
        sortOrder: Int
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.systemImage = systemImage
        self.sortOrder = sortOrder
    }
}

public struct ContentCatalog: Hashable, Sendable {
    public let situations: [GuideSituation]
    public let articles: [GuideArticle]

    public init(situations: [GuideSituation], articles: [GuideArticle]) {
        self.situations = situations
        self.articles = articles
    }

    public func articles(for situationID: GuideSituation.ID?) -> [GuideArticle] {
        guard let situationID else { return [] }
        return articles
            .filter { $0.situations.contains(situationID) }
            .sorted(by: Self.articleSort)
    }

    public func situation(id: GuideSituation.ID?) -> GuideSituation? {
        guard let id else { return nil }
        return situations.first { $0.id == id }
    }

    public func article(id: GuideArticle.ID?) -> GuideArticle? {
        guard let id else { return nil }
        return articles.first { $0.id == id }
    }

    private static func articleSort(_ lhs: GuideArticle, _ rhs: GuideArticle) -> Bool {
        if lhs.priority.sortIndex != rhs.priority.sortIndex {
            return lhs.priority.sortIndex < rhs.priority.sortIndex
        }
        let lhsPeriod = lhs.periods.compactMap(GuidePeriod.init(rawValue:)).map(\.sortIndex).min() ?? Int.max
        let rhsPeriod = rhs.periods.compactMap(GuidePeriod.init(rawValue:)).map(\.sortIndex).min() ?? Int.max
        if lhsPeriod != rhsPeriod {
            return lhsPeriod < rhsPeriod
        }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}
