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
        didSet { syncDisplayedArticleSelection() }
    }
    var showsFavoritesOnly = false {
        didSet { syncDisplayedArticleSelection() }
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

    var displayedArticles: [GuideArticle] {
        guard let catalog else { return [] }

        let articles: [GuideArticle]
        if !hasSearchQuery {
            articles = showsFavoritesOnly ? catalog.articles : visibleArticles
        } else {
            articles = catalog.searchArticles(matching: searchQuery)
        }

        let favoritesFiltered = showsFavoritesOnly
            ? articles.filter { favoriteArticleIDs.contains($0.id) }
            : articles
        return catalog.filterArticles(favoritesFiltered, using: articleFilter)
    }

    var articleFilter: GuideArticleFilter {
        GuideArticleFilter(category: selectedCategory, period: selectedPeriod)
    }

    var hasActiveArticleFilters: Bool {
        articleFilter.isActive
    }

    var availableCategories: [String] {
        catalog?.availableCategories ?? []
    }

    var availablePeriods: [GuidePeriod] {
        catalog?.availablePeriods ?? []
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
        return displayedArticles.first { $0.id == selectedArticleID }
    }

    func load() {
        do {
            let catalog = try repository.loadBundledCatalog()
            loadState = .ready(catalog)
            if selectedSituationID == nil {
                selectedSituationID = catalog.situations.first?.id
            }
            reconcileFavorites(with: catalog)
            syncDisplayedArticleSelection()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectSituation(_ id: GuideSituation.ID?) {
        searchQuery = ""
        showsFavoritesOnly = false
        selectedSituationID = id
        syncDisplayedArticleSelection()
    }

    func selectArticle(_ id: GuideArticle.ID?) {
        guard let id else {
            selectedArticleID = nil
            return
        }
        guard displayedArticles.contains(where: { $0.id == id }) else { return }
        selectedArticleID = id
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
        if let selectedArticleID,
           displayedArticles.contains(where: { $0.id == selectedArticleID }) {
            return
        }
        selectedArticleID = displayedArticles.first?.id
    }

    private func reconcileFavorites(with catalog: ContentCatalog) {
        let validIDs = Set(catalog.articles.map(\.id))
        let reconciled = favoriteArticleIDs.intersection(validIDs)
        guard reconciled != favoriteArticleIDs else { return }
        favoriteArticleIDs = reconciled
        favoriteStore.save(reconciled)
    }
}
