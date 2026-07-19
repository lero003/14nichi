import FourteenDayCore
import SwiftUI

struct ArticleDetailView: View {
    let article: GuideArticle

    private var renderedBody: AttributedString {
        (try? AttributedString(
            markdown: article.bodyMarkdown,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        )) ?? AttributedString(article.bodyMarkdown)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if article.isDraftFixture {
                    draftBanner
                }
                summaryBlock
                bodyBlock
                sourcesBlock
            }
            .padding()
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(article.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PriorityBadge(priority: article.priority)
                ForEach(article.periodLabels, id: \.self) { label in
                    PeriodChip(label: label)
                }
                if article.isDraftFixture {
                    DraftStatusLabel(status: article.reviewStatus)
                }
                Spacer(minLength: 0)
            }

            Text(article.title)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var draftBanner: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("未監修の制作確認用コンテンツ")
                    .font(.headline)
                Text("緊急時の案内として使用しないでください。正式な行動手順は監修完了後に公開します。")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.orange)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("注意。未監修の制作確認用コンテンツです。緊急時の案内として使用しないでください。")
    }

    private var summaryBlock: some View {
        Text(article.summary)
            .font(.title3)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bodyBlock: some View {
        Text(renderedBody)
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { _ in
                // Offline-first: keep users inside the note while reading.
                .discarded
            })
    }

    private var sourcesBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情報源")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("本文は自前で整理し、参照先は権利に配慮した利用形態で記録します。長い原文の転載は行いません。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if article.sources.isEmpty {
                Text("この記事にはまだ情報源が登録されていません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(article.sources) { source in
                    SourceCard(source: source)
                }
            }

            if let reviewedAt = article.reviewedAt, let reviewedBy = article.reviewedBy {
                Text("最終確認: \(reviewedAt) / \(reviewedBy)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SourceCard: View {
    let source: GuideArticle.Source

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(source.title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(source.usage.displayName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }

            Text(source.publisher)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(source.url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text("確認日: \(source.accessedAt)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(source.rightsNote)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            if source.usage == .shortQuote, let excerpt = source.excerpt, source.hasExcerpt {
                Text("「\(excerpt)」")
                    .font(.caption)
                    .italic()
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("引用。\(excerpt)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: GuideArticle(
                metadata: GuideArticle.Metadata(
                    id: "preview",
                    title: "停電時の画面確認サンプル",
                    summary: "オフライン記事の表示確認用です。",
                    path: "emergency/preview.md",
                    category: "electricity",
                    priority: .critical,
                    situations: ["blackout"],
                    periods: ["immediate"],
                    region: "jp",
                    reviewStatus: .draft,
                    reviewedAt: nil,
                    reviewedBy: nil,
                    sources: [
                        GuideArticle.Source(
                            id: "cao-bousai",
                            title: "内閣府 防災情報のページ",
                            publisher: "内閣府",
                            url: URL(string: "https://www.bousai.go.jp/")!,
                            accessedAt: "2026-07-20",
                            usage: .linkOnly,
                            rightsNote: "公式サイトへの参照のみ。本文は転載しない。"
                        ),
                    ]
                ),
                bodyMarkdown: """
                ## 最初の5分

                - 安全を確認する
                - 照明を確保する
                """
            )
        )
    }
}
