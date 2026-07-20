import Foundation
import Testing
@testable import FourteenDayCore

@Suite("Article discovery")
struct ArticleDiscoveryTests {
    @Test("search finds Japanese title text")
    func findsTitle() {
        #expect(catalog.searchArticles(matching: "停電").map(\.id) == ["blackout"])
    }

    @Test("search finds body text without case or width sensitivity")
    func findsBodyText() {
        #expect(catalog.searchArticles(matching: "ｖｏｉｃｅｏｖｅｒ").map(\.id) == ["blackout"])
    }

    @Test("multiple search terms all need to match")
    func requiresEveryToken() {
        #expect(catalog.searchArticles(matching: "制作 VoiceOver").map(\.id) == ["blackout"])
        #expect(catalog.searchArticles(matching: "停電 水道").isEmpty)
    }

    @Test("search includes situation and source metadata")
    func findsMetadata() {
        #expect(catalog.searchArticles(matching: "断水").map(\.id) == ["water"])
        #expect(catalog.searchArticles(matching: "総務省").map(\.id) == ["blackout"])
    }

    @Test("blank queries do not return the whole catalog")
    func rejectsBlankQuery() {
        #expect(catalog.searchArticles(matching: "  \n ").isEmpty)
    }

    private var catalog: ContentCatalog {
        ContentCatalog(
            situations: [
                GuideSituation(
                    id: "blackout",
                    title: "停電した",
                    summary: "電気が使えない",
                    systemImage: "bolt.slash",
                    sortOrder: 1
                ),
                GuideSituation(
                    id: "water-outage",
                    title: "断水した",
                    summary: "水道が使えない",
                    systemImage: "drop",
                    sortOrder: 2
                ),
            ],
            articles: [
                article(
                    id: "blackout",
                    title: "停電時の制作確認",
                    summary: "読み上げを確認する記事",
                    situation: "blackout",
                    body: "VoiceOverで本文を確認する",
                    publisher: "総務省"
                ),
                article(
                    id: "water",
                    title: "水の記事",
                    summary: "表示サンプル",
                    situation: "water-outage",
                    body: "制作確認用の本文",
                    publisher: "厚生労働省"
                ),
            ]
        )
    }

    private func article(
        id: String,
        title: String,
        summary: String,
        situation: String,
        body: String,
        publisher: String
    ) -> GuideArticle {
        GuideArticle(
            metadata: GuideArticle.Metadata(
                id: id,
                title: title,
                summary: summary,
                path: "emergency/\(id).md",
                category: "fixture",
                priority: .normal,
                situations: [situation],
                periods: ["immediate"],
                region: "jp",
                reviewStatus: .draft,
                reviewedAt: nil,
                reviewedBy: nil,
                sources: [
                    GuideArticle.Source(
                        id: "source-\(id)",
                        title: "公式情報",
                        publisher: publisher,
                        url: URL(string: "https://example.com/\(id)")!,
                        accessedAt: "2026-07-20",
                        usage: .linkOnly,
                        rightsNote: "テスト用"
                    ),
                ]
            ),
            bodyMarkdown: body
        )
    }
}
