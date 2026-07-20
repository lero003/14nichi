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
}
