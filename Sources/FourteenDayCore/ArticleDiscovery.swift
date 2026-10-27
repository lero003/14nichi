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
    /// ホームの緊急ショートカットから開く、確認済みの最優先記事。
    /// manifest で `shortcutArticleID` が指定されていればそれを優先し、
    /// 未指定なら approved / critical / immediate の先頭記事へフォールバックする。
    func emergencyShortcutArticle(
        for situationID: GuideSituation.ID
    ) -> GuideArticle? {
        if let shortcutArticleID = situation(id: situationID)?.shortcutArticleID,
           let shortcut = article(id: shortcutArticleID),
           shortcut.reviewStatus == .approved,
           shortcut.situations.contains(situationID),
           shortcut.periods.contains(GuidePeriod.immediate.rawValue) {
            return shortcut
        }

        return articles(for: situationID).first { article in
            article.reviewStatus == .approved
                && article.priority == .critical
                && article.periods.contains(GuidePeriod.immediate.rawValue)
        }
    }

    /// 記事末尾に出す関連導線。同じ状況に属する記事だけを既存の編集順で返す。
    func relatedArticles(
        to article: GuideArticle,
        limit: Int = 3
    ) -> [GuideArticle] {
        guard limit > 0 else { return [] }
        let situationIDs = Set(article.situations)

        return articles.enumerated()
            .filter { _, candidate in
                candidate.id != article.id
                    && candidate.reviewStatus == .approved
                    && candidate.situations.contains(where: situationIDs.contains)
            }
            .sorted {
                let lhs = $0.element
                let rhs = $1.element
                if lhs.priority.sortIndex != rhs.priority.sortIndex {
                    return lhs.priority.sortIndex < rhs.priority.sortIndex
                }
                let lhsPeriod = lhs.periods
                    .compactMap(GuidePeriod.init(rawValue:))
                    .map(\.sortIndex)
                    .min() ?? Int.max
                let rhsPeriod = rhs.periods
                    .compactMap(GuidePeriod.init(rawValue:))
                    .map(\.sortIndex)
                    .min() ?? Int.max
                if lhsPeriod != rhsPeriod {
                    return lhsPeriod < rhsPeriod
                }
                return $0.offset < $1.offset
            }
            .prefix(limit)
            .map(\.element)
    }

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
