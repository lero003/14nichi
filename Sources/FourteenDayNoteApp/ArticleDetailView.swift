import FourteenDayCore
import SwiftUI

struct ArticleDetailView: View {
    let article: GuideArticle
    /// 上部ナビゲーションに出す状況名。本文の大きなタイトルと重複させない。
    let contextTitle: String?
    let isFavorite: Bool
    let relatedArticles: [GuideArticle]
    let onToggleFavorite: () -> Void
    let onOpenRelated: (GuideArticle) -> Void
    @Environment(ReadabilitySettings.self) private var readability
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var revealed = false

    var body: some View {
        let blocks = GuideMarkdownParser.displayBlocks(
            article.bodyMarkdown,
            omittingLeadingTitle: article.title
        )
        let sections = GuideArticleOutline.sections(in: blocks)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: readability.sectionSpacing) {
                    header
                    compactSafetyBanner
                    summaryBlock
                    sectionJumpBar(sections, proxy: proxy)
                    bodyBlock(blocks)
                    detailedSafetyFooter
                    relatedArticlesBlock
                    sourcesBlock
                }
                .padding(AppTheme.contentGutter)
                .frame(maxWidth: readability.textSize.contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(revealed || reduceMotion ? 1 : 0)
                .offset(y: revealed || reduceMotion ? 0 : 10)
            }
            .navigationTitle(contextTitle ?? article.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        isFavorite ? "お気に入りから外す" : "お気に入りに追加",
                        systemImage: isFavorite ? "heart.fill" : "heart",
                        action: onToggleFavorite
                    )
                    .accessibilityHint("この記事のお気に入り状態を端末内に保存します")
                }
            }
        }
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
                ReviewStatusLabel(status: article.reviewStatus)
            }

            Text(article.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

        }
    }

    /// ファーストビュー用の短い注意。詳細は `detailedSafetyFooter` へ回す。
    private var compactSafetyBanner: some View {
        Label {
            Text(article.isDraftFixture
                 ? "制作確認用です。緊急時の案内に使わないでください。"
                 : "一般的な目安です。最新の公式情報と現場の指示を優先してください。")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: article.isDraftFixture ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .imageScale(.small)
        }
        .foregroundStyle(article.isDraftFixture ? .orange : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill((article.isDraftFixture ? Color.orange : Color.secondary).opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(article.isDraftFixture
                            ? "注意。制作確認用コンテンツです。緊急時の案内として使用しないでください。"
                            : "注意。一般的な目安です。最新の公式情報と現場の指示を優先してください。詳細は記事末尾にあります。")
    }

    /// 記事末尾の詳細な限界・優先順位の説明。本文のあと・情報源の前に置く。
    private var detailedSafetyFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.isDraftFixture ? "制作確認用コンテンツ" : "この記事の使い方と限界")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text(article.isDraftFixture
                 ? "緊急時の案内として使用しないでください。自治体・消防・警察・気象庁などの発表を優先してください。"
                 : "公的一次情報と照合した一般的な目安です。地域、建物、体調、災害の進行や情報更新によって適切な行動は変わり、不正確または古くなる可能性があります。119・110、自治体、消防、警察、気象庁、医療機関、インフラ事業者と現場の指示を、この記事より優先してください。専門資格者による個別の診断や現場判断の代わりではありません。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
        .accessibilityElement(children: .combine)
    }

    private var summaryBlock: some View {
        Text(article.summary)
            .font(readability.prefersBoldBody ? .title3.weight(.semibold) : .title3)
            .foregroundStyle(.secondary)
            .lineSpacing(readability.resolvedLineSpacing * 0.5)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 長い記事でも、必要な節へ迷わず移れるようにする。
    @ViewBuilder
    private func sectionJumpBar(
        _ sections: [GuideArticleSection],
        proxy: ScrollViewProxy
    ) -> some View {
        if sections.count >= 2 {
            VStack(alignment: .leading, spacing: 8) {
                Label("記事の構成", systemImage: "list.bullet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                WrapLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(sections) { section in
                        Button {
                            withAnimation(AppTheme.gentle(reduceMotion: reduceMotion)) {
                                proxy.scrollTo(section.anchorID, anchor: .center)
                            }
                        } label: {
                            Text(section.label)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .foregroundStyle(AppTheme.accent)
                                .background(
                                    AppTheme.accent.opacity(colorScheme == .dark ? 0.20 : 0.09),
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            AppTheme.accent.opacity(colorScheme == .dark ? 0.38 : 0.18),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(section.title)
                        .accessibilityHint("この見出し付近へ移動します")
                        .accessibilityIdentifier("article.sectionJump.\(section.id)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
            }
        }
    }

    private func bodyBlock(_ blocks: [GuideMarkdownBlock]) -> some View {
        ArticleMarkdownView(
            blocks: blocks,
            prefersBoldBody: readability.prefersBoldBody,
            lineSpacing: readability.resolvedLineSpacing
        )
    }

    @ViewBuilder
    private var relatedArticlesBlock: some View {
        if relatedArticles.isEmpty == false {
            SurfaceCard(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("次に確認する")
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text("同じ状況に関係する確認済みの記事です。")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    ForEach(relatedArticles) { related in
                        Button {
                            onOpenRelated(related)
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(related.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(related.summary)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if related.id != relatedArticles.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
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
            ),
            contextTitle: "停電した",
            isFavorite: false,
            relatedArticles: [],
            onToggleFavorite: {},
            onOpenRelated: { _ in }
        )
    }
    .environment(ReadabilitySettings())
}
