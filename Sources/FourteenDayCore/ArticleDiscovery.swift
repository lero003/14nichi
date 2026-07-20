import Foundation

public struct GuideArticleFilter: Equatable, Sendable {
    public var category: String?
    public var period: GuidePeriod?

    public init(category: String? = nil, period: GuidePeriod? = nil) {
        self.category = category
        self.period = period
    }

    public var isActive: Bool {
        category != nil || period != nil
    }

    public func matches(_ article: GuideArticle) -> Bool {
        if let category, article.category != category {
            return false
        }
        if let period, article.periods.contains(period.rawValue) == false {
            return false
        }
        return true
    }
}

public extension ContentCatalog {
    /// 同梱済み記事だけを対象にした、通信不要の全文検索。
    func searchArticles(matching query: String) -> [GuideArticle] {
        let tokens = Self.searchTokens(from: query)
        guard !tokens.isEmpty else { return [] }

        return articles.filter { article in
            let situationText = article.situations.compactMap { situation(id: $0) }
                .flatMap { [$0.title, $0.summary] }
            let sourceText = article.sources.flatMap { [$0.title, $0.publisher] }
            let searchableText = ([
                article.title,
                article.summary,
                article.bodyMarkdown,
                article.category,
            ] + situationText + sourceText)
                .joined(separator: "\n")
                .foldedForGuideSearch

            return tokens.allSatisfy(searchableText.contains)
        }
    }

    func filterArticles(
        _ candidates: [GuideArticle],
        using filter: GuideArticleFilter
    ) -> [GuideArticle] {
        guard filter.isActive else { return candidates }
        return candidates.filter(filter.matches)
    }

    var availableCategories: [String] {
        Array(Set(articles.map(\.category))).sorted {
            GuideCategory.displayName(for: $0)
                .localizedStandardCompare(GuideCategory.displayName(for: $1)) == .orderedAscending
        }
    }

    var availablePeriods: [GuidePeriod] {
        GuidePeriod.allCases.filter { period in
            articles.contains { $0.periods.contains(period.rawValue) }
        }
    }

    private static func searchTokens(from query: String) -> [String] {
        query
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0).foldedForGuideSearch }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var foldedForGuideSearch: String {
        folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "ja_JP")
        )
    }
}
