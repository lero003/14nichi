import Testing
@testable import FourteenDayCore

@Suite("Guide Markdown")
struct GuideMarkdownTests {
    @Test("headings, quotes, lists, and paragraphs become semantic blocks")
    func parsesArticleStructure() {
        let markdown = """
        # 制作確認用

        > 未監修のサンプルです。

        ## 確認項目

        - **太字**を保つ
        - 二つ目

        最初の行
        続きの行
        """

        #expect(GuideMarkdownParser.parse(markdown) == [
            .heading(level: 1, text: "制作確認用"),
            .blockQuote("未監修のサンプルです。"),
            .heading(level: 2, text: "確認項目"),
            .bulletList(["**太字**を保つ", "二つ目"]),
            .paragraph("最初の行 続きの行"),
        ])
    }

    @Test("plain hash marks do not become headings")
    func requiresSpaceAfterHeadingMarker() {
        #expect(GuideMarkdownParser.parse("##見出しではない") == [
            .paragraph("##見出しではない"),
        ])
    }

    @Test("an empty document has no display blocks")
    func handlesEmptyDocument() {
        #expect(GuideMarkdownParser.parse("\n\n").isEmpty)
    }

    @Test("a duplicate leading article title is omitted only for display")
    func omitsDuplicateLeadingTitle() {
        let markdown = """
        # 地震：最初の数分ですること

        本文です。
        """

        #expect(
            GuideMarkdownParser.displayBlocks(
                markdown,
                omittingLeadingTitle: "地震：最初の数分ですること"
            ) == [.paragraph("本文です。")]
        )
        #expect(GuideMarkdownParser.parse(markdown).first == .heading(
            level: 1,
            text: "地震：最初の数分ですること"
        ))
    }

    @Test("a different or non-leading H1 remains visible")
    func preservesMeaningfulHeadings() {
        #expect(
            GuideMarkdownParser.displayBlocks(
                "# 別の見出し\n\n本文",
                omittingLeadingTitle: "記事タイトル"
            ).first == .heading(level: 1, text: "別の見出し")
        )
        #expect(
            GuideMarkdownParser.displayBlocks(
                "導入\n\n# 記事タイトル",
                omittingLeadingTitle: "記事タイトル"
            ).last == .heading(level: 1, text: "記事タイトル")
        )
    }
}
