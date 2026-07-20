import FourteenDayCore
import SwiftUI

struct ArticleBrowserView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ReadabilitySettings.self) private var readability
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var appeared = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            situationColumn
        } content: {
            articleColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar { browserToolbar }
        .onAppear {
            guard !appeared else { return }
            appeared = true
        }
    }

    private var situationColumn: some View {
        List(selection: situationSelection) {
            Section {
                ForEach(Array((model.catalog?.situations ?? []).enumerated()), id: \.element.id) { index, situation in
                    SituationRow(
                        situation: situation,
                        articleCount: model.catalog?.articles(for: situation.id).count ?? 0,
                        generousSpacing: readability.prefersGenerousSpacing
                    )
                    .tag(situation.id)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .opacity(appeared || reduceMotion ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 8)
                    .animation(
                        reduceMotion
                            ? nil
                            : .spring(response: 0.42, dampingFraction: 0.86).delay(Double(index) * 0.04),
                        value: appeared
                    )
                }
            } header: {
                Text("状況を選ぶ")
                    .font(.subheadline.weight(.semibold))
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    OfflineCapabilityBadge()
                    Text("通信なしで、いま必要な記事へ進めます。文字サイズは右上のボタンから変えられます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("いま何が起きていますか？")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 360)
#endif
    }

    private var articleColumn: some View {
        List(selection: articleSelection) {
            if let situation = model.selectedSituation {
                Section {
                    ForEach(model.visibleArticles) { article in
                        ArticleRow(
                            article: article,
                            generousSpacing: readability.prefersGenerousSpacing
                        )
                        .tag(article.id)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                } header: {
                    Text(situation.title)
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    if model.visibleArticles.isEmpty {
                        Text("この状況の記事はまだありません。")
                            .font(.callout)
                    } else {
                        Text("優先度の高い順に並んでいます。")
                            .font(.callout)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(model.selectedSituation?.title ?? "記事")
        .overlay {
            if model.selectedSituationID == nil {
                emptyState(
                    title: "状況を選んでください",
                    systemImage: "checklist",
                    description: "左側からいまの状況を選ぶと、関連記事が表示されます。"
                )
            } else if model.visibleArticles.isEmpty {
                emptyState(
                    title: "記事がありません",
                    systemImage: "doc",
                    description: "この状況の制作コンテンツはまだありません。"
                )
            }
        }
        .animation(AppTheme.spring(reduceMotion: reduceMotion), value: model.selectedSituationID)
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 270, ideal: 340, max: 420)
#endif
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let article = model.selectedArticle {
            ArticleDetailView(article: article)
                .id(article.id)
                .transition(
                    reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .offset(y: 6)),
                            removal: .opacity
                        )
                )
        } else {
            emptyState(
                title: "記事を選んでください",
                systemImage: "book",
                description: "状況と記事を選ぶと、オフラインで本文を読めます。"
            )
        }
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
                .font(.body)
        }
    }

    @ToolbarContentBuilder
    private var browserToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                model.isReadabilityPresented = true
            } label: {
                Label("読みやすさ", systemImage: "textformat.size")
            }
            .help("文字サイズと余白を変更")
            .accessibilityHint("文字を大きくしたり、行間を広げたりできます")

            Button {
                model.isAboutPresented = true
            } label: {
                Label("このアプリについて", systemImage: "info.circle")
            }
            .help("アプリの目的と安全上の注意")
        }
    }

    private var situationSelection: Binding<GuideSituation.ID?> {
        Binding(
            get: { model.selectedSituationID },
            set: { newValue in
                withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                    model.selectSituation(newValue)
                }
            }
        )
    }

    private var articleSelection: Binding<GuideArticle.ID?> {
        Binding(
            get: { model.selectedArticleID },
            set: { newValue in
                withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                    model.selectArticle(newValue)
                }
            }
        )
    }
}

private struct SituationRow: View {
    let situation: GuideSituation
    let articleCount: Int
    var generousSpacing: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            IconWell(systemName: situation.systemImage)
            VStack(alignment: .leading, spacing: generousSpacing ? 6 : 4) {
                Text(situation.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(situation.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(articleCount == 0 ? "記事なし" : "記事 \(articleCount)件")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, generousSpacing ? 8 : 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(articleCount == 0 ? "記事なし" : "記事 \(articleCount)件")
    }
}

private struct ArticleRow: View {
    let article: GuideArticle
    var generousSpacing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: generousSpacing ? 10 : 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    articleTitle
                    Spacer(minLength: 0)
                    PriorityBadge(priority: article.priority)
                }
                VStack(alignment: .leading, spacing: 8) {
                    articleTitle
                    PriorityBadge(priority: article.priority)
                }
            }

            Text(article.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FlowChips {
                ForEach(article.periodLabels, id: \.self) { label in
                    PeriodChip(label: label)
                }
                if article.isDraftFixture {
                    DraftStatusLabel(status: article.reviewStatus)
                }
            }
        }
        .padding(.vertical, generousSpacing ? 8 : 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var articleTitle: some View {
        Text(article.title)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// チップが折り返せる簡易フロー。
private struct FlowChips<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        // macOS / iOS 共通で自然に折り返す
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content() }
            VStack(alignment: .leading, spacing: 8) { content() }
        }
    }
}
