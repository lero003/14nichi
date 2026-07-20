import FourteenDayCore
import SwiftUI

struct ArticleBrowserView: View {
    @Bindable var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ReadabilitySettings.self) private var readability

    /// コンパクト幅専用。選択の再タップ不能や詳細への引き戻しを避ける。
    @State private var compactPath: [GuideCompactRoute] = []
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var appeared = false

    /// iPhone / 狭い幅は NavigationStack。広い幅と Mac は Split。
    private var usesCompactNavigation: Bool {
#if os(iOS)
        horizontalSizeClass != .regular
#else
        false
#endif
    }

    var body: some View {
        Group {
            if usesCompactNavigation {
                compactBrowser
            } else {
                splitBrowser
            }
        }
        .sensoryFeedback(.selection, trigger: model.favoriteArticleIDs)
        .onAppear {
            guard !appeared else { return }
            appeared = true
        }
        .onChange(of: model.showsFavoritesOnly) { _, isFavorites in
            guard usesCompactNavigation else { return }
            if isFavorites {
                // お気に入りはルート直下の一覧として見せる
                compactPath = []
            }
        }
        .onChange(of: model.searchQuery) { _, query in
            guard usesCompactNavigation else { return }
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // 検索開始時は状況ドリルダウンを解除して結果をルートに出す
                compactPath = []
            }
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            // 幅切り替え後は model を正として compact path を組み直す（取り残し・空 path での詳細残留を防ぐ）
            if usesCompactNavigation {
                rebuildCompactPathFromModel()
            }
        }
        .onChange(of: compactPath) { _, newPath in
            guard usesCompactNavigation else { return }
            reconcileModel(with: newPath)
        }
    }

    // MARK: - Compact (iPhone): NavigationStack

    private var compactBrowser: some View {
        NavigationStack(path: $compactPath) {
            situationRootList
                .navigationTitle("防災ガイド")
                .navigationDestination(for: GuideCompactRoute.self) { route in
                    switch route {
                    case .situation(let situationID):
                        articleListScreen(situationID: situationID)
                    case .article(let articleID):
                        detailScreen(articleID: articleID)
                    }
                }
                .toolbar { browserToolbar }
        }
        .searchable(text: $model.searchQuery, prompt: "記事を検索")
    }

    private var situationRootList: some View {
        List {
            if model.showsFavoritesOnly || model.hasSearchQuery {
                articleSection(title: model.articleListTitle)
            } else {
                Section {
                    GuideHeroCard(
                        situationCount: model.catalog?.situations.count ?? 0,
                        articleCount: model.catalog?.articles.count ?? 0
                    )
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(Array((model.catalog?.situations ?? []).enumerated()), id: \.element.id) { index, situation in
                        Button {
                            openSituation(situation.id)
                        } label: {
                            SituationRow(
                                situation: situation,
                                articleCount: model.catalog?.articles(for: situation.id).count ?? 0,
                                generousSpacing: readability.prefersGenerousSpacing
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.sidebar)
#endif
        .overlay {
            if model.showsFavoritesOnly || model.hasSearchQuery {
                articleEmptyOverlay
            }
        }
    }

    private func articleListScreen(situationID: GuideSituation.ID) -> some View {
        List {
            articleSection(title: model.articleListTitle)
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.sidebar)
#endif
        .navigationTitle(model.catalog?.situation(id: situationID)?.title ?? "記事")
        .overlay { articleEmptyOverlay }
        .onAppear {
            // スタック戻り後も一覧の候補集合をこの状況に合わせる（検索状態は壊さない）
            model.alignSelectedSituation(situationID)
        }
    }

    @ViewBuilder
    private func articleSection(title: String) -> some View {
        Section {
            ForEach(model.displayedArticles) { article in
                Button {
                    openArticle(article.id)
                } label: {
                    ArticleRow(
                        article: article,
                        isFavorite: model.isFavorite(article.id),
                        generousSpacing: readability.prefersGenerousSpacing
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } header: {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if model.hasActiveArticleFilters {
                    Text("絞り込み: \(model.articleFilterSummary)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !model.displayedArticles.isEmpty {
                Text("記事 \(model.displayedArticles.count)件")
                    .font(.callout)
            }
        }
    }

    @ViewBuilder
    private func detailScreen(articleID: GuideArticle.ID) -> some View {
        if let article = model.catalog?.article(id: articleID) {
            ArticleDetailView(
                article: article,
                isFavorite: model.isFavorite(article.id),
                onToggleFavorite: { model.toggleFavorite(article.id) }
            )
            .onAppear {
                model.selectArticle(articleID, requireDisplayed: false)
            }
        } else {
            emptyState(
                title: "記事を開けません",
                systemImage: "doc",
                description: "記事が見つかりません。一覧に戻って選び直してください。"
            )
        }
    }

    private func openSituation(_ id: GuideSituation.ID) {
        withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
            model.selectSituation(id)
            compactPath = [.situation(id)]
        }
    }

    private func openArticle(_ id: GuideArticle.ID) {
        // catalog 上に存在する記事なら詳細へ進む（一覧フィルタで弾かれて固まるのを防ぐ）
        guard model.catalog?.article(id: id) != nil else { return }
        withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
            model.selectArticle(id, requireDisplayed: false)
            // 検索・お気に入り中はルートから記事へ。状況経由なら situation の上に積む。
            if model.showsFavoritesOnly || model.hasSearchQuery {
                compactPath = [.article(id)]
            } else if let situationID = model.selectedSituationID {
                compactPath = [.situation(situationID), .article(id)]
            } else {
                compactPath = [.article(id)]
            }
        }
    }

    /// model の選択から compact 用 path を復元する（サイズクラス切り替え用）。
    private func rebuildCompactPathFromModel() {
        if model.showsFavoritesOnly || model.hasSearchQuery {
            if let articleID = model.selectedArticleID,
               model.catalog?.article(id: articleID) != nil {
                compactPath = [.article(articleID)]
            } else {
                compactPath = []
            }
            return
        }

        if let situationID = model.selectedSituationID {
            if let articleID = model.selectedArticleID,
               model.catalog?.article(id: articleID) != nil {
                compactPath = [.situation(situationID), .article(articleID)]
            } else {
                compactPath = [.situation(situationID)]
            }
        } else if let articleID = model.selectedArticleID,
                  model.catalog?.article(id: articleID) != nil {
            compactPath = [.article(articleID)]
        } else {
            compactPath = []
        }
    }

    /// path を正として model を同期（システム戻るで path だけ変わったとき用）。
    private func reconcileModel(with path: [GuideCompactRoute]) {
        var situationID: GuideSituation.ID?
        var articleID: GuideArticle.ID?
        for route in path {
            switch route {
            case .situation(let id):
                situationID = id
            case .article(let id):
                articleID = id
            }
        }
        model.reconcileCompactRoute(situationID: situationID, articleID: articleID)
    }

    // MARK: - Regular / Mac: NavigationSplitView

    private var splitBrowser: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            splitSituationColumn
        } content: {
            splitArticleColumn
        } detail: {
            splitDetailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar { browserToolbar }
    }

    private var splitSituationColumn: some View {
        List(selection: situationSelection) {
            Section {
                GuideHeroCard(
                    situationCount: model.catalog?.situations.count ?? 0,
                    articleCount: model.catalog?.articles.count ?? 0,
                    showsMark: false
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(model.catalog?.situations ?? [], id: \.id) { situation in
                    SituationRow(
                        situation: situation,
                        articleCount: model.catalog?.articles(for: situation.id).count ?? 0,
                        generousSpacing: readability.prefersGenerousSpacing,
                        isSelected: model.selectedSituationID == situation.id
                    )
                    .tag(Optional(situation.id))
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } header: {
                Text("状況を選ぶ")
                    .font(.subheadline.weight(.semibold))
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    OfflineCapabilityBadge()
                    Text("通信なしで、いま必要な記事へ進めます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
        .navigationTitle("いま何が起きていますか？")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 360)
#endif
    }

    private var splitArticleColumn: some View {
        List(selection: articleSelection) {
            if model.catalog != nil {
                Section {
                    ForEach(model.displayedArticles) { article in
                        ArticleRow(
                            article: article,
                            isFavorite: model.isFavorite(article.id),
                            generousSpacing: readability.prefersGenerousSpacing
                        )
                        .tag(Optional(article.id))
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.articleListTitle)
                            .font(.subheadline.weight(.semibold))
                        if model.hasActiveArticleFilters {
                            Text("絞り込み: \(model.articleFilterSummary)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    if !model.displayedArticles.isEmpty {
                        Text("記事 \(model.displayedArticles.count)件")
                            .font(.callout)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
        .navigationTitle(model.articleListTitle)
        .searchable(text: $model.searchQuery, prompt: "記事を検索")
        .overlay { articleEmptyOverlay }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 270, ideal: 340, max: 420)
#endif
    }

    @ViewBuilder
    private var splitDetailColumn: some View {
        if let article = model.selectedArticle {
            ArticleDetailView(
                article: article,
                isFavorite: model.isFavorite(article.id),
                onToggleFavorite: { model.toggleFavorite(article.id) }
            )
            .id(article.id)
        } else {
            emptyState(
                title: "記事を選んでください",
                systemImage: "book",
                description: "状況と記事を選ぶと、オフラインで本文を読めます。"
            )
        }
    }

    // MARK: - Shared chrome

    @ViewBuilder
    private var articleEmptyOverlay: some View {
        if model.hasActiveArticleFilters, model.displayedArticles.isEmpty {
            filteredEmptyState
        } else if model.hasSearchQuery, model.displayedArticles.isEmpty {
            ContentUnavailableView.search(text: model.searchQuery)
        } else if model.showsFavoritesOnly, model.displayedArticles.isEmpty {
            emptyState(
                title: "お気に入りはまだありません",
                systemImage: "heart",
                description: "記事を開いて「お気に入りに追加」を選ぶと、ここからすぐ確認できます。"
            )
        } else if !model.showsFavoritesOnly,
                  !model.hasSearchQuery,
                  model.selectedSituationID == nil,
                  usesCompactNavigation == false {
            emptyState(
                title: "状況を選んでください",
                systemImage: "checklist",
                description: "左側からいまの状況を選ぶと、関連記事が表示されます。"
            )
        } else if model.selectedSituationID != nil, model.displayedArticles.isEmpty {
            emptyState(
                title: "記事がありません",
                systemImage: "doc",
                description: "この状況の制作コンテンツはまだありません。"
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

    private var filteredEmptyState: some View {
        ContentUnavailableView {
            Label("条件に一致する記事がありません", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("現在の検索・お気に入り・状況に「\(model.articleFilterSummary)」を重ねた結果です。")
                .font(.body)
        } actions: {
            Button("絞り込みを解除") {
                withAnimation(AppTheme.gentle(reduceMotion: reduceMotion)) {
                    model.clearArticleFilters()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var browserToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Picker("カテゴリ", selection: categoryFilterSelection) {
                    Text("すべてのカテゴリ").tag(nil as String?)
                    ForEach(model.availableCategories, id: \.self) { category in
                        Text(GuideCategory.displayName(for: category)).tag(Optional(category))
                    }
                }

                Picker("行動時期", selection: periodFilterSelection) {
                    Text("すべての時期").tag(nil as GuidePeriod?)
                    ForEach(model.availablePeriods, id: \.rawValue) { period in
                        Text(period.displayName).tag(Optional(period))
                    }
                }

                if model.hasActiveArticleFilters {
                    Divider()
                    Button("絞り込みを解除", systemImage: "xmark.circle") {
                        model.clearArticleFilters()
                    }
                }
            } label: {
                Label(
                    model.hasActiveArticleFilters ? "絞り込み中" : "記事を絞り込む",
                    systemImage: model.hasActiveArticleFilters
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle"
                )
            }
            .help(model.hasActiveArticleFilters ? model.articleFilterSummary : "カテゴリと行動時期で絞り込む")
            .accessibilityValue(model.articleFilterSummary)

            Button {
                withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                    model.toggleFavoritesFilter()
                    if usesCompactNavigation {
                        compactPath = []
                    }
                }
            } label: {
                Label(
                    model.showsFavoritesOnly ? "すべての記事を表示" : "お気に入りだけ表示",
                    systemImage: model.showsFavoritesOnly ? "heart.fill" : "heart"
                )
            }
            .help(
                model.showsFavoritesOnly
                    ? "状況別の記事一覧へ戻る"
                    : "お気に入り \(model.favoriteArticleIDs.count)件を表示"
            )
            .accessibilityValue(model.showsFavoritesOnly ? "選択中" : "未選択")

            Button {
                model.presentedSheet = .readability
            } label: {
                Label("読みやすさ", systemImage: "textformat.size")
            }
            .help("文字サイズと余白を変更")
            .accessibilityHint("文字を大きくしたり、行間を広げたりできます")

            Button {
                model.presentedSheet = .about
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
                    model.selectArticle(newValue, requireDisplayed: true)
                }
            }
        )
    }

    private var categoryFilterSelection: Binding<String?> {
        Binding(
            get: { model.selectedCategory },
            set: { model.selectedCategory = $0 }
        )
    }

    private var periodFilterSelection: Binding<GuidePeriod?> {
        Binding(
            get: { model.selectedPeriod },
            set: { model.selectedPeriod = $0 }
        )
    }
}

/// iPhone のガイド階層。
private enum GuideCompactRoute: Hashable {
    case situation(GuideSituation.ID)
    case article(GuideArticle.ID)
}

private struct SituationRow: View {
    let situation: GuideSituation
    let articleCount: Int
    var generousSpacing: Bool
    var isSelected: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            IconWell(systemName: situation.systemImage)
            VStack(alignment: .leading, spacing: generousSpacing ? 6 : 4) {
                Text(situation.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
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
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.coral)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(generousSpacing ? 16 : 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(isSelected ? AppTheme.accent.opacity(0.12) : cardFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? AppTheme.accent.opacity(0.45) : AppTheme.surfaceStroke,
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(articleCount == 0 ? "記事なし" : "記事 \(articleCount)件")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var cardFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.055)
            : AppTheme.ivory.opacity(0.58)
    }
}

private struct ArticleRow: View {
    let article: GuideArticle
    let isFavorite: Bool
    var generousSpacing: Bool
    @Environment(\.colorScheme) private var colorScheme

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
                ReviewStatusLabel(status: article.reviewStatus)
                if isFavorite {
                    FavoriteStatusLabel()
                }
            }
        }
        .padding(generousSpacing ? 16 : 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .fill(cardFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var articleTitle: some View {
        Text(article.title)
            .font(.headline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var cardFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.055)
            : AppTheme.ivory.opacity(0.58)
    }
}

/// チップが折り返せる簡易フロー。
private struct FlowChips<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content() }
            VStack(alignment: .leading, spacing: 8) { content() }
        }
    }
}
