import Foundation

/// 記事本文の見出しから作る、読み進め用の目次。
/// `id` は本文ブロックの位置で、表示側のスクロール先アンカーに使う。
public struct GuideArticleSection: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let label: String
    public let level: Int

    public init(id: Int, title: String, label: String, level: Int) {
        self.id = id
        self.title = title
        self.label = label
        self.level = level
    }

    /// 本文ブロックのスクロール先。目次ボタン自身のIDと衝突しないよう名前空間を付ける。
    public var anchorID: String {
        Self.anchorID(blockIndex: id)
    }

    public static func anchorID(blockIndex: Int) -> String {
        "article-block-\(blockIndex)"
    }
}

public enum GuideArticleOutline {
    /// 表示ブロックに含まれる見出しを、本文の並び順で返す。
    public static func sections(in blocks: [GuideMarkdownBlock]) -> [GuideArticleSection] {
        blocks.enumerated().compactMap { index, block in
            guard case .heading(let level, let text) = block else { return nil }
            return GuideArticleSection(
                id: index,
                title: text,
                label: shortLabel(for: text),
                level: level
            )
        }
    }

    /// 記事共通の5項目は、短い移動ラベルへ寄せる。
    public static func shortLabel(for heading: String) -> String {
        let trimmed = heading.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("最初の5分") {
            return "最初の5分"
        }
        if trimmed.contains("今日中") {
            return "今日中"
        }
        if trimmed.contains("明日以降") {
            return "明日以降"
        }
        if trimmed.contains("やってはいけない") {
            return "やってはいけない"
        }
        if trimmed.contains("状況が悪化") {
            return "悪化したとき"
        }
        if trimmed.contains("この記事の限界") {
            return "この記事の限界"
        }
        return trimmed
    }
}
