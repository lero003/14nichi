import FourteenDayCore
import SwiftUI

struct ArticleDetailView: View {
    let article: GuideArticle
    @Environment(ReadabilitySettings.self) private var readability
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: readability.sectionSpacing) {
                header
                if article.isDraftFixture {
                    draftBanner
                }
                summaryBlock
                bodyBlock
                sourcesBlock
            }
            .padding(AppTheme.contentGutter)
            .frame(maxWidth: readability.textSize.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(revealed || reduceMotion ? 1 : 0)
            .offset(y: revealed || reduceMotion ? 0 : 10)
        }
        .navigationTitle(article.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                revealed = true
            }
        }
        .onChange(of: article.id) { _, _ in
            revealed = false
            withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                revealed = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowMeta {
                PriorityBadge(priority: article.priority)
                ForEach(article.periodLabels, id: \.self) { label in
                    PeriodChip(label: label)
                }
                if article.isDraftFixture {
                    DraftStatusLabel(status: article.reviewStatus)
                }
            }

            Text(article.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var draftBanner: some View {
        Label {
            VStack(alignment: .leading, spacing: 6) {
                Text("未監修の制作確認用コンテンツ")
                    .font(.headline)
                Text("緊急時の案内として使用しないでください。正式な行動手順は監修完了後に公開します。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.large)
        }
        .foregroundStyle(.orange)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("注意。未監修の制作確認用コンテンツです。緊急時の案内として使用しないでください。")
    }

    private var summaryBlock: some View {
        Text(article.summary)
            .font(readability.prefersBoldBody ? .title3.weight(.semibold) : .title3)
            .foregroundStyle(.secondary)
            .lineSpacing(readability.resolvedLineSpacing * 0.5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bodyBlock: some View {
        ArticleMarkdownView(
            markdown: article.bodyMarkdown,
            prefersBoldBody: readability.prefersBoldBody,
            lineSpacing: readability.resolvedLineSpacing
        )
    }

    private var sourcesBlock: some View {
        SurfaceCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("情報源")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text("本文は自前で整理し、参照先は権利に配慮した利用形態で記録します。長い原文の転載は行いません。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(readability.resolvedLineSpacing * 0.4)
                    .fixedSize(horizontal: false, vertical: true)

                if article.sources.isEmpty {
                    Text("この記事にはまだ情報源が登録されていません。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(article.sources) { source in
                        SourceCard(source: source, lineSpacing: readability.resolvedLineSpacing)
                        if source.id != article.sources.last?.id {
                            Divider()
                        }
                    }
                }

                if let reviewedAt = article.reviewedAt, let reviewedBy = article.reviewedBy {
                    Text("最終確認: \(reviewedAt) / \(reviewedBy)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
    }
}

private struct SourceCard: View {
    let source: GuideArticle.Source
    var lineSpacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    sourceTitle
                    Spacer(minLength: 0)
                    usageBadge
                }
                VStack(alignment: .leading, spacing: 8) {
                    sourceTitle
                    usageBadge
                }
            }

            Text(source.publisher)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(source.url.absoluteString)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Link(destination: source.url) {
                Label("公式サイトを開く（オンライン）", systemImage: "arrow.up.right.square")
            }
            .font(.body.weight(.semibold))
            .accessibilityHint("通信を使用して外部サイトを開きます")

            Text("確認日: \(source.accessedAt)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(source.rightsNote)
                .font(.callout)
                .lineSpacing(lineSpacing * 0.4)
                .fixedSize(horizontal: false, vertical: true)

            if source.usage == .shortQuote, let excerpt = source.excerpt, source.hasExcerpt {
                Text("「\(excerpt)」")
                    .font(.callout)
                    .italic()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityLabel("引用。\(excerpt)")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
    }

    private var sourceTitle: some View {
        Text(source.title)
            .font(.body.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var usageBadge: some View {
        Text(source.usage.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

private struct FlowMeta<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content() }
            VStack(alignment: .leading, spacing: 8) { content() }
        }
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
    .environment(ReadabilitySettings())
}
