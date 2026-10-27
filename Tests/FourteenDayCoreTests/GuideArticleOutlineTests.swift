import Testing
@testable import FourteenDayCore

@Suite("Guide article outline")
struct GuideArticleOutlineTests {
    private let markdown = """
    # 地震：最初の数分ですること

    導入の段落。

    ## 最初の5分ですること

    - 身を守る。

    ## 今日中にすること

    - 安全を確認する。

    ## 明日以降にすること

    - 備えを見直す。

    ## やってはいけないこと

    - 無理に外へ出ない。

    ## 状況が悪化した場合

    - 119番へ通報する。

    ## この記事の限界

    - 一般的な目安です。
    """

    @Test("leading title is omitted from displayed blocks and outline")
    func omitsLeadingTitle() {
        let blocks = GuideMarkdownParser.displayBlocks(
            markdown,
            omittingLeadingTitle: "地震：最初の数分ですること"
        )
        let sections = GuideArticleOutline.sections(in: blocks)

        #expect(sections.map(\.title) == [
            "最初の5分ですること",
            "今日中にすること",
            "明日以降にすること",
            "やってはいけないこと",
            "状況が悪化した場合",
            "この記事の限界",
        ])
        #expect(sections.map(\.label) == [
            "最初の5分",
            "今日中",
            "明日以降",
            "やってはいけない",
            "悪化したとき",
            "この記事の限界",
        ])
        #expect(sections.first?.anchorID == "article-block-1")
    }

    @Test("section ids point at heading block positions")
    func sectionIDsMatchBlockPositions() {
        let blocks = GuideMarkdownParser.displayBlocks(
            markdown,
            omittingLeadingTitle: "地震：最初の数分ですること"
        )
        let sections = GuideArticleOutline.sections(in: blocks)

        for section in sections {
            guard case .heading(let level, let text) = blocks[section.id] else {
                Issue.record("section \(section.label) does not point at a heading")
                continue
            }
            #expect(level == section.level)
            #expect(text == section.title)
        }
    }

    @Test("uncommon headings keep their own label")
    func keepsUnknownHeading() {
        #expect(GuideArticleOutline.shortLabel(for: "補足：連絡先の決め方") == "補足：連絡先の決め方")
    }

    @Test("articles without headings have no outline")
    func noHeadingsNoSections() {
        let blocks = GuideMarkdownParser.displayBlocks("本文だけの記事です。", omittingLeadingTitle: nil)
        #expect(GuideArticleOutline.sections(in: blocks).isEmpty)
    }
}
