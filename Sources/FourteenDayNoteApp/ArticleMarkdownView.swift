import FourteenDayCore
import SwiftUI

/// Markdownの各見出しを独立した要素として描画し、VoiceOverの見出し移動を可能にする。
struct ArticleMarkdownView: View {
    let markdown: String
    let prefersBoldBody: Bool
    let lineSpacing: CGFloat

    private var blocks: [GuideMarkdownBlock] {
        GuideMarkdownParser.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: max(lineSpacing, 12)) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(_ block: GuideMarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inlineMarkdown(text))
                .font(headingFont(level: level))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

        case .paragraph(let text):
            Text(inlineMarkdown(text))
                .font(prefersBoldBody ? .body.weight(.medium) : .body)
                .lineSpacing(lineSpacing)
                .fixedSize(horizontal: false, vertical: true)

        case .bulletList(let items):
            VStack(alignment: .leading, spacing: max(lineSpacing, 8)) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .accessibilityHidden(true)
                        Text(inlineMarkdown(item))
                            .font(prefersBoldBody ? .body.weight(.medium) : .body)
                            .lineSpacing(lineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .blockQuote(let text):
            Text(inlineMarkdown(text))
                .font(prefersBoldBody ? .body.weight(.medium) : .body)
                .lineSpacing(lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 14)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 4)
                        .accessibilityHidden(true)
                }
        }
    }

    private func inlineMarkdown(_ source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(source)
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: .title.weight(.bold)
        case 2: .title2.weight(.bold)
        default: .title3.weight(.semibold)
        }
    }
}
