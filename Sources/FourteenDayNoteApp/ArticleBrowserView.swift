import FourteenDayCore
import SwiftUI

struct ArticleBrowserView: View {
    @Bindable var model: AppModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            situationColumn
        } content: {
            articleColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var situationColumn: some View {
        List(selection: situationSelection) {
            Section {
                ForEach(model.catalog?.situations ?? []) { situation in
                    SituationRow(
                        situation: situation,
                        articleCount: model.catalog?.articles(for: situation.id).count ?? 0
                    )
                    .tag(situation.id)
                }
            } header: {
                Text("状況を選ぶ")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    OfflineCapabilityBadge()
                    Text("通信なしで、いま必要な記事へ進めます。")
                        .font(.caption)
                }
                .padding(.top, 4)
            }
        }
        .navigationTitle("いま何が起きていますか？")
        .toolbar { browserToolbar }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 220, ideal: 270, max: 340)
#endif
    }

    private var articleColumn: some View {
        List(selection: articleSelection) {
            if let situation = model.selectedSituation {
                Section {
                    ForEach(model.visibleArticles) { article in
                        ArticleRow(article: article)
                            .tag(article.id)
                    }
                } header: {
                    Text(situation.title)
                } footer: {
                    if model.visibleArticles.isEmpty {
                        Text("この状況の記事はまだありません。")
                    } else {
                        Text("優先度の高い順に並んでいます。")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(model.selectedSituation?.title ?? "記事")
        .overlay {
            if model.selectedSituationID == nil {
                ContentUnavailableView(
                    "状況を選んでください",
                    systemImage: "checklist",
                    description: Text("左側からいまの状況を選ぶと、関連記事が表示されます。")
                )
            } else if model.visibleArticles.isEmpty {
                ContentUnavailableView(
                    "記事がありません",
                    systemImage: "doc",
                    description: Text("この状況の制作コンテンツはまだありません。")
                )
            }
        }
        .toolbar { browserToolbar }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 250, ideal: 320, max: 400)
#endif
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let article = model.selectedArticle {
            ArticleDetailView(article: article)
                .toolbar { browserToolbar }
        } else {
            ContentUnavailableView(
                "記事を選んでください",
                systemImage: "book",
                description: Text("状況と記事を選ぶと、オフラインで本文を読めます。")
            )
            .toolbar { browserToolbar }
        }
    }

    @ToolbarContentBuilder
    private var browserToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
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
            set: { model.selectSituation($0) }
        )
    }

    private var articleSelection: Binding<GuideArticle.ID?> {
        Binding(
            get: { model.selectedArticleID },
            set: { model.selectArticle($0) }
        )
    }
}

private struct SituationRow: View {
    let situation: GuideSituation
    let articleCount: Int

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(situation.title)
                    .font(.headline)
                Text(situation.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: situation.systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityValue(articleCount == 0 ? "記事なし" : "記事 \(articleCount)件")
    }
}

private struct ArticleRow: View {
    let article: GuideArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                PriorityBadge(priority: article.priority)
            }

            Text(article.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(article.periodLabels, id: \.self) { label in
                    PeriodChip(label: label)
                }
                if article.isDraftFixture {
                    DraftStatusLabel(status: article.reviewStatus)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
