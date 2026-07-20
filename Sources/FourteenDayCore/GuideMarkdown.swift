import Foundation

/// 記事本文をアクセシビリティ上意味のある表示単位へ分けたもの。
public enum GuideMarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bulletList([String])
    case blockQuote(String)
}

public enum GuideMarkdownParser {
    public static func parse(_ markdown: String) -> [GuideMarkdownBlock] {
        var blocks: [GuideMarkdownBlock] = []
        var paragraphLines: [String] = []
        var bulletItems: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
            paragraphLines.removeAll(keepingCapacity: true)
        }

        func flushBullets() {
            guard !bulletItems.isEmpty else { return }
            blocks.append(.bulletList(bulletItems))
            bulletItems.removeAll(keepingCapacity: true)
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                flushBullets()
                continue
            }

            if let heading = heading(from: line) {
                flushParagraph()
                flushBullets()
                blocks.append(heading)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                bulletItems.append(String(line.dropFirst(2)))
            } else if line.hasPrefix("> ") {
                flushParagraph()
                flushBullets()
                blocks.append(.blockQuote(String(line.dropFirst(2))))
            } else {
                flushBullets()
                paragraphLines.append(line)
            }
        }

        flushParagraph()
        flushBullets()
        return blocks
    }

    private static func heading(from line: String) -> GuideMarkdownBlock? {
        let markerCount = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(markerCount),
              line.dropFirst(markerCount).first == " "
        else {
            return nil
        }
        let text = String(line.dropFirst(markerCount + 1))
        guard !text.isEmpty else { return nil }
        return .heading(level: markerCount, text: text)
    }
}
