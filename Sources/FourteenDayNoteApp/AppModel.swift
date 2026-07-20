import FourteenDayCore
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    enum LoadState: Equatable {
        case loading
        case ready(ContentCatalog)
        case failed(String)

        static func == (lhs: LoadState, rhs: LoadState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                true
            case (.ready(let l), .ready(let r)):
                l == r
            case (.failed(let l), .failed(let r)):
                l == r
            default:
                false
            }
        }
    }

    private(set) var loadState: LoadState = .loading
    var selectedSituationID: GuideSituation.ID?
    var selectedArticleID: GuideArticle.ID?
    var searchQuery = "" {
        didSet {
            pruneArticleFiltersToAvailableOptions()
            syncDisplayedArticleSelection()
        }
    }
    var showsFavoritesOnly = false {
        didSet {
            pruneArticleFiltersToAvailableOptions()
            syncDisplayedArticleSelection()
        }
    }
    var selectedCategory: String? {
        didSet { syncDisplayedArticleSelection() }
    }
    var selectedPeriod: GuidePeriod? {
        didSet { syncDisplayedArticleSelection() }
    }
    private(set) var favoriteArticleIDs: Set<GuideArticle.ID>
    var isAboutPresented = false
    var isReadabilityPresented = false

    let readability: ReadabilitySettings
    private let repository: ContentRepository
    private let favoriteStore: FavoriteArticleStore

    init(
        repository: ContentRepository = ContentRepository(),
        readability: ReadabilitySettings = ReadabilitySettings(),
        favoriteStore: FavoriteArticleStore = FavoriteArticleStore()
    ) {
        self.repository = repository
        self.readability = readability
        self.favoriteStore = favoriteStore
        favoriteArticleIDs = favoriteStore.load()
    }

    var catalog: ContentCatalog? {
        if case .ready(let catalog) = loadState {
            return catalog
        }
        return nil
    }

    var visibleArticles: [GuideArticle] {
        guard let catalog else { return [] }
        return catalog.articles(for: selectedSituationID)
    }

    var hasSearchQuery: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// カテゴリ・時期フィルタを掛ける前の候補（状況・検索・お気に入りまで反映）。
    var filterBaseArticles: [GuideArticle] {
        guard let catalog else { return [] }

        let articles: [GuideArticle]
        if hasSearchQuery {
            articles = catalog.searchArticles(matching: searchQuery)
        } else if showsFavoritesOnly {
            articles = catalog.articles
        } else {
            articles = visibleArticles
        }

        if showsFavoritesOnly {
            return articles.filter { favoriteArticleIDs.contains($0.id) }
        }
        return articles
    }

    var displayedArticles: [GuideArticle] {
        guard let catalog else { return [] }
        return catalog.filterArticles(filterBaseArticles, using: articleFilter)
    }

    var articleFilter: GuideArticleFilter {
        GuideArticleFilter(category: selectedCategory, period: selectedPeriod)
    }

    var hasActiveArticleFilters: Bool {
        articleFilter.isActive
    }

    /// いまの候補集合から選べるカテゴリだけを返す（他状況のカテゴリで空振りしない）。
    var availableCategories: [String] {
        Array(Set(filterBaseArticles.map(\.category))).sorted {
            GuideCategory.displayName(for: $0)
                .localizedStandardCompare(GuideCategory.displayName(for: $1)) == .orderedAscending
        }
    }

    var availablePeriods: [GuidePeriod] {
        GuidePeriod.allCases.filter { period in
            filterBaseArticles.contains { $0.periods.contains(period.rawValue) }
        }
    }

    var articleFilterSummary: String {
        var labels: [String] = []
        if let selectedCategory {
            labels.append(GuideCategory.displayName(for: selectedCategory))
        }
        if let selectedPeriod {
            labels.append(selectedPeriod.displayName)
        }
        return labels.isEmpty ? "絞り込みなし" : labels.joined(separator: "・")
    }

    var articleListTitle: String {
        if showsFavoritesOnly {
            return hasSearchQuery ? "お気に入りの検索結果" : "お気に入り"
        }
        if hasSearchQuery {
            return "検索結果"
        }
        return selectedSituation?.title ?? "記事"
    }

    var selectedSituation: GuideSituation? {
        catalog?.situation(id: selectedSituationID)
    }

    var selectedArticle: GuideArticle? {
        guard let selectedArticleID else { return nil }
        // Split では一覧にある記事を優先。詳細復元では catalog からも引ける。
        if let displayed = displayedArticles.first(where: { $0.id == selectedArticleID }) {
            return displayed
        }
        return catalog?.article(id: selectedArticleID)
    }

    func load() {
        do {
            let catalog = try repository.loadBundledCatalog()
            loadState = .ready(catalog)
            // 起動時は状況・記事とも未選択。iPhone で状況 index を飛ばして詳細へ入らない。
            // （wide レイアウトでは左に状況一覧、中央は「状況を選んでください」。）
            if selectedSituationID != nil,
               catalog.situation(id: selectedSituationID) == nil {
                selectedSituationID = nil
            }
            selectedArticleID = nil
            reconcileFavorites(with: catalog)
            pruneArticleFiltersToAvailableOptions()
            syncDisplayedArticleSelection()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectSituation(_ id: GuideSituation.ID?) {
        // 検索・お気に入りは状況ドリルダウンと排他
        searchQuery = ""
        showsFavoritesOnly = false
        selectedSituationID = id
        // 状況を変えたら記事選択を外す（一覧へ戻す）
        selectedArticleID = nil
        pruneArticleFiltersToAvailableOptions()
        syncDisplayedArticleSelection()
    }

    /// ナビ階層の復元用。検索・お気に入りは触らず、状況IDだけ合わせる。
    func alignSelectedSituation(_ id: GuideSituation.ID) {
        guard selectedSituationID != id else { return }
        selectedSituationID = id
        selectedArticleID = nil
        pruneArticleFiltersToAvailableOptions()
        syncDisplayedArticleSelection()
    }

    /// - Parameter requireDisplayed: `true` のとき一覧上の記事だけ選択可（Split の選択用）。
    ///   詳細画面の復元では `false` にして catalog 上のIDを許す。
    func selectArticle(_ id: GuideArticle.ID?, requireDisplayed: Bool = true) {
        guard let id else {
            selectedArticleID = nil
            return
        }
        if requireDisplayed {
            guard displayedArticles.contains(where: { $0.id == id }) else { return }
        } else {
            guard catalog?.article(id: id) != nil else { return }
        }
        selectedArticleID = id
    }

    /// 詳細を閉じる／一覧に戻るとき用。
    func clearArticleSelection() {
        selectedArticleID = nil
    }

    /// Compact の NavigationStack path を正として選択状態を合わせる。
    /// 戻るジェスチャで path だけが変わったときに、状況・記事の選択が取り残されないようにする。
    func reconcileCompactRoute(
        situationID: GuideSituation.ID?,
        articleID: GuideArticle.ID?
    ) {
        if let situationID {
            if selectedSituationID != situationID {
                selectedSituationID = situationID
                pruneArticleFiltersToAvailableOptions()
            }
        } else if showsFavoritesOnly == false, hasSearchQuery == false, selectedSituationID != nil {
            // ルート（状況一覧）に戻ったとき。検索・お気に入り表示中は状況IDを触らない。
            selectedSituationID = nil
            pruneArticleFiltersToAvailableOptions()
        }

        if let articleID {
            // 詳細が path に残っている間は一覧フィルタ外でも保持する
            selectArticle(articleID, requireDisplayed: false)
        } else if selectedArticleID != nil {
            clearArticleSelection()
        }
    }

    func isFavorite(_ articleID: GuideArticle.ID) -> Bool {
        favoriteArticleIDs.contains(articleID)
    }

    func toggleFavorite(_ articleID: GuideArticle.ID) {
        if favoriteArticleIDs.contains(articleID) {
            favoriteArticleIDs.remove(articleID)
        } else {
            favoriteArticleIDs.insert(articleID)
        }
        favoriteStore.save(favoriteArticleIDs)
        syncDisplayedArticleSelection()
    }

    func toggleFavoritesFilter() {
        showsFavoritesOnly.toggle()
    }

    func clearArticleFilters() {
        selectedCategory = nil
        selectedPeriod = nil
    }

    private func syncDisplayedArticleSelection() {
        guard catalog != nil else {
            selectedArticleID = nil
            return
        }
        // 一覧に無い選択は捨てる。先頭記事への自動ジャンプはしない（状況 index を飛ばす原因になる）。
        if let selectedArticleID,
           displayedArticles.contains(where: { $0.id == selectedArticleID }) {
            return
        }
        selectedArticleID = nil
    }

    /// いまの候補に存在しないカテゴリ・時期が残っていると一覧が空になるため落とす。
    private func pruneArticleFiltersToAvailableOptions() {
        if let selectedCategory, availableCategories.contains(selectedCategory) == false {
            self.selectedCategory = nil
        }
        if let selectedPeriod, availablePeriods.contains(selectedPeriod) == false {
            self.selectedPeriod = nil
        }
    }

    private func reconcileFavorites(with catalog: ContentCatalog) {
        let validIDs = Set(catalog.articles.map(\.id))
        let reconciled = favoriteArticleIDs.intersection(validIDs)
        guard reconciled != favoriteArticleIDs else { return }
        favoriteArticleIDs = reconciled
        favoriteStore.save(reconciled)
    }
}
