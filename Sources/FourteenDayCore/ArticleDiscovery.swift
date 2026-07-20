import Foundation

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
