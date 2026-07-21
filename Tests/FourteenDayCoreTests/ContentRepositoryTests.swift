import Foundation
import Testing
@testable import FourteenDayCore

@Suite("Bundled content")
struct ContentRepositoryTests {
    @Test("manifest and approved Markdown content load together")
    func loadsBundledArticle() throws {
        let catalog = try ContentRepository().loadBundledCatalog()

        #expect(catalog.situations.map(\.id).contains("earthquake"))
        #expect(catalog.situations.map(\.id).contains("blackout"))
        #expect(catalog.situations.count >= 10)
        #expect(catalog.articles.count >= 25)
        #expect(catalog.articles.allSatisfy { $0.reviewStatus == .approved })
        // 記事ごとの再確認日を許容しつつ、approvedに必要な記録が欠けていないことを確認する。
        #expect(catalog.articles.allSatisfy { $0.reviewedAt?.isEmpty == false })
        #expect(catalog.articles.allSatisfy { $0.reviewedBy?.isEmpty == false })
        #expect(catalog.articles.allSatisfy { !$0.sources.isEmpty })
        #expect(catalog.articles(for: "blackout").map(\.id).contains("blackout-first-actions"))
        #expect(catalog.articles(for: "blackout").map(\.id).contains("blackout-phone-battery"))

        let blackout = try #require(catalog.articles.first { $0.id == "blackout-first-actions" })
        #expect(blackout.sources.count >= 2)
        #expect(blackout.sources.allSatisfy { $0.url.scheme == "https" })
        #expect(blackout.title.contains("停電"))
    }

    @Test("articles for a situation prefer primary-situation content first")
    func sortsArticlesBySituationAffinityThenPriority() throws {
        let catalog = try ContentRepository().loadBundledCatalog()
        let blackout = catalog.articles(for: "blackout")
        let earthquake = catalog.articles(for: "earthquake")

        #expect(blackout.isEmpty == false)
        #expect(blackout.map(\.id).first == "blackout-first-actions")
        #expect(blackout.map(\.id).contains("blackout-phone-battery"))

        // 複数状況に紐づく関連記事が、当該状況の本体記事より前に来ない
        #expect(earthquake.map(\.id).first == "earthquake-first-actions")
        if let gasIndex = earthquake.map(\.id).firstIndex(of: "gas-outage-first-actions"),
           let primaryIndex = earthquake.map(\.id).firstIndex(of: "earthquake-first-actions") {
            #expect(primaryIndex < gasIndex)
        }

        let priorities = blackout.map(\.priority)
        if let firstCritical = priorities.firstIndex(of: .critical),
           let firstNormal = priorities.firstIndex(of: .normal) {
            #expect(firstCritical < firstNormal)
        }
    }

    @Test("front matter is removed from displayed body")
    func removesFrontMatter() {
        let source = """
        ---
        id: sample
        ---

        # 本文
        """

        #expect(ContentRepository.removingFrontMatter(from: source) == "\n# 本文")
    }

    @Test("manifest rejects duplicate situation IDs")
    func rejectsDuplicateSituationIDs() {
        let situation = GuideSituation(
            id: "blackout",
            title: "停電",
            summary: "summary",
            systemImage: "bolt.slash",
            sortOrder: 1
        )
        let manifest = Manifest(
            schemaVersion: 1,
            situations: [situation, situation],
            articles: []
        )

        #expect(throws: ContentRepository.RepositoryError.duplicateSituationID("blackout")) {
            try ContentRepository.validate(manifest: manifest)
        }
    }

    @Test("manifest rejects references to unknown situations")
    func rejectsUnknownSituation() {
        let manifest = Manifest(
            schemaVersion: 1,
            situations: [],
            articles: [articleMetadata(situations: ["unknown"])]
        )

        #expect(
            throws: ContentRepository.RepositoryError.unknownSituation(
                articleID: "sample",
                situationID: "unknown"
            )
        ) {
            try ContentRepository.validate(manifest: manifest)
        }
    }

    @Test("approved content requires review evidence")
    func rejectsIncompleteApprovedReview() {
        let situation = GuideSituation(
            id: "blackout",
            title: "停電",
            summary: "summary",
            systemImage: "bolt.slash",
            sortOrder: 1
        )
        let manifest = Manifest(
            schemaVersion: 1,
            situations: [situation],
            articles: [articleMetadata(reviewStatus: .approved)]
        )

        #expect(throws: ContentRepository.RepositoryError.incompleteApprovedReview("sample")) {
            try ContentRepository.validate(manifest: manifest)
        }
    }

    @Test("sources require https and rights metadata")
    func rejectsInvalidSourceURL() {
        let bad = sampleSource(url: URL(string: "http://example.com")!)
        #expect(
            throws: ContentRepository.RepositoryError.invalidSource(
                articleID: "sample",
                sourceID: "src-1",
                reason: "url は https である必要があります"
            )
        ) {
            try ContentRepository.validateSource(bad, articleID: "sample")
        }
    }

    @Test("short quotes must stay short and present")
    func rejectsLongShortQuote() {
        let long = String(repeating: "あ", count: ContentRepository.maxShortQuoteLength + 1)
        let source = sampleSource(usage: .shortQuote, excerpt: long)
        #expect(
            throws: ContentRepository.RepositoryError.invalidSource(
                articleID: "sample",
                sourceID: "src-1",
                reason: "excerpt が \(ContentRepository.maxShortQuoteLength) 文字を超えています（長い転載は禁止）"
            )
        ) {
            try ContentRepository.validateSource(source, articleID: "sample")
        }
    }

    @Test("linkOnly sources cannot carry excerpts")
    func rejectsExcerptOnLinkOnly() {
        let source = sampleSource(usage: .linkOnly, excerpt: "転載した本文")
        #expect(
            throws: ContentRepository.RepositoryError.invalidSource(
                articleID: "sample",
                sourceID: "src-1",
                reason: "linkOnly では excerpt を置かないでください（転載を避けるため）"
            )
        ) {
            try ContentRepository.validateSource(source, articleID: "sample")
        }
    }

    @Test("relative Markdown paths cannot escape the content directory")
    func rejectsEscapingPaths() {
        #expect(ContentRepository.isValidRelativeMarkdownPath("emergency/guide.md"))
        #expect(ContentRepository.isValidRelativeMarkdownPath("../guide.md") == false)
        #expect(ContentRepository.isValidRelativeMarkdownPath("/tmp/guide.md") == false)
        #expect(ContentRepository.isValidRelativeMarkdownPath("emergency/guide.txt") == false)
    }

    @Test(
        "access dates must be real Gregorian dates",
        arguments: ["0000-01-01", "2026-02-30", "2026-13-01", "2026-7-20", "not-a-date"]
    )
    func rejectsInvalidAccessDates(_ value: String) {
        #expect(ContentRepository.isValidAccessDate(value) == false)
    }

    @Test("access dates accept leap days")
    func acceptsValidLeapDay() {
        #expect(ContentRepository.isValidAccessDate("2024-02-29"))
    }

    @Test("priority and period labels are localized for UI")
    func providesDisplayLabels() {
        #expect(GuideArticle.Priority.critical.displayName == "最優先")
        #expect(GuidePeriod.immediate.displayName == "いま")
        #expect(GuidePeriod.day1.displayName == "初日")
        #expect(GuideCategory.electricity.displayName == "電気")
        #expect(GuideCategory.displayName(for: "future-category") == "future-category")
        #expect(GuideArticle.Source.Usage.paraphrase.displayName == "要約・言い換え")
    }

    private func articleMetadata(
        situations: [String] = ["blackout"],
        reviewStatus: GuideArticle.ReviewStatus = .draft,
        sources: [GuideArticle.Source] = []
    ) -> GuideArticle.Metadata {
        GuideArticle.Metadata(
            id: "sample",
            title: "Sample",
            summary: "Summary",
            path: "emergency/sample.md",
            category: "electricity",
            priority: .normal,
            situations: situations,
            periods: ["immediate"],
            region: "jp",
            reviewStatus: reviewStatus,
            reviewedAt: nil,
            reviewedBy: nil,
            sources: sources
        )
    }

    private func sampleSource(
        url: URL = URL(string: "https://www.bousai.go.jp/")!,
        usage: GuideArticle.Source.Usage = .linkOnly,
        excerpt: String? = nil
    ) -> GuideArticle.Source {
        GuideArticle.Source(
            id: "src-1",
            title: "内閣府 防災情報",
            publisher: "内閣府",
            url: url,
            accessedAt: "2026-07-20",
            usage: usage,
            rightsNote: "参照リンクのみ",
            excerpt: excerpt
        )
    }
}
