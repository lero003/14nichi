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

    @Test("category and period filters can be combined")
    func combinesFilters() {
        let electricityNow = GuideArticleFilter(category: "electricity", period: .immediate)
        let electricityDayOne = GuideArticleFilter(category: "electricity", period: .day1)

        #expect(catalog.filterArticles(catalog.articles, using: electricityNow).map(\.id) == ["blackout"])
        #expect(catalog.filterArticles(catalog.articles, using: electricityDayOne).isEmpty)
    }

    @Test("an inactive filter preserves candidate order")
    func inactiveFilterPreservesCandidates() {
        let candidates = Array(catalog.articles.reversed())

        #expect(
            catalog.filterArticles(candidates, using: GuideArticleFilter()).map(\.id)
                == candidates.map(\.id)
        )
    }

    @Test("available filter options come only from bundled metadata")
    func derivesAvailableOptions() {
        #expect(Set(catalog.availableCategories) == ["electricity", "water"])
        #expect(catalog.availablePeriods == [.immediate, .day1])
    }

    @Test("emergency shortcuts require approved critical immediate content")
    func resolvesEmergencyShortcut() {
        let approved = article(
            id: "approved",
            title: "最初の行動",
            summary: "確認済み",
            situation: "blackout",
            body: "本文",
            publisher: "総務省",
            category: "electricity",
            priority: .critical,
            reviewStatus: .approved,
            periods: ["immediate"]
        )
        let candidates = ContentCatalog(
            situations: catalog.situations,
            articles: catalog.articles + [approved]
        )

        #expect(candidates.emergencyShortcutArticle(for: "blackout")?.id == "approved")
        #expect(candidates.emergencyShortcutArticle(for: "water-outage") == nil)
    }

    @Test("an explicit shortcut article wins over the critical fallback")
    func resolvesExplicitShortcut() {
        let decision = article(
            id: "decision",
            title: "避難するか留まるか",
            summary: "判断",
            situation: "evacuation",
            body: "本文",
            publisher: "内閣府",
            category: "evacuation",
            priority: .high,
            reviewStatus: .approved,
            periods: ["immediate"]
        )
        let fallback = article(
            id: "critical",
            title: "最優先の持ち物",
            summary: "持ち物",
            situation: "evacuation",
            body: "本文",
            publisher: "内閣府",
            category: "evacuation",
            priority: .critical,
            reviewStatus: .approved,
            periods: ["immediate"]
        )
        let situation = GuideSituation(
            id: "evacuation",
            title: "避難を考える",
            summary: "避難の判断",
            systemImage: "figure.walk",
            sortOrder: 3,
            shortcutArticleID: "decision"
        )
        let candidates = ContentCatalog(
            situations: [situation],
            articles: [fallback, decision]
        )

        #expect(candidates.emergencyShortcutArticle(for: "evacuation")?.id == "decision")
    }

    @Test("related articles keep editorial priority and exclude the current article")
    func resolvesRelatedArticles() {
        let current = article(
            id: "current",
            title: "現在の記事",
            summary: "現在",
            situation: "blackout",
            body: "本文",
            publisher: "総務省",
            category: "electricity",
            priority: .critical,
            reviewStatus: .approved,
            periods: ["immediate"]
        )
        let next = article(
            id: "next",
            title: "次の記事",
            summary: "次",
            situation: "blackout",
            body: "本文",
            publisher: "総務省",
            category: "electricity",
            priority: .high,
            reviewStatus: .approved,
            periods: ["day1"]
        )
        let manifestFirst = article(
            id: "manifest-first",
            title: "末尾の題名",
            summary: "manifest先",
            situation: "blackout",
            body: "本文",
            publisher: "総務省",
            category: "electricity",
            priority: .normal,
            reviewStatus: .approved,
            periods: ["day1"]
        )
        let manifestSecond = article(
            id: "manifest-second",
            title: "先頭の題名",
            summary: "manifest後",
            situation: "blackout",
            body: "本文",
            publisher: "総務省",
            category: "electricity",
            priority: .normal,
            reviewStatus: .approved,
            periods: ["day1"]
        )
        let candidates = ContentCatalog(
            situations: catalog.situations,
            articles: [next, manifestFirst, manifestSecond, current] + catalog.articles
        )

        #expect(
            candidates.relatedArticles(to: current).map(\.id)
                == ["next", "manifest-first", "manifest-second"]
        )
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
                    publisher: "総務省",
                    category: "electricity",
                    periods: ["immediate"]
                ),
                article(
                    id: "water",
                    title: "水の記事",
                    summary: "表示サンプル",
                    situation: "water-outage",
                    body: "制作確認用の本文",
                    publisher: "厚生労働省",
                    category: "water",
                    periods: ["day1"]
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
        publisher: String,
        category: String,
        priority: GuideArticle.Priority = .normal,
        reviewStatus: GuideArticle.ReviewStatus = .draft,
        periods: [String]
    ) -> GuideArticle {
        GuideArticle(
            metadata: GuideArticle.Metadata(
                id: id,
                title: title,
                summary: summary,
                path: "emergency/\(id).md",
                category: category,
                priority: priority,
                situations: [situation],
                periods: periods,
                region: "jp",
                reviewStatus: reviewStatus,
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
