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
    var isAboutPresented = false
    var isReadabilityPresented = false

    let readability: ReadabilitySettings
    private let repository: ContentRepository

    init(
        repository: ContentRepository = ContentRepository(),
        readability: ReadabilitySettings = ReadabilitySettings()
    ) {
        self.repository = repository
        self.readability = readability
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

    var selectedSituation: GuideSituation? {
        catalog?.situation(id: selectedSituationID)
    }

    var selectedArticle: GuideArticle? {
        guard let catalog else { return nil }
        if let selectedArticleID,
           let match = visibleArticles.first(where: { $0.id == selectedArticleID }) {
            return match
        }
        return catalog.article(id: selectedArticleID)
    }

    func load() {
        do {
            let catalog = try repository.loadBundledCatalog()
            loadState = .ready(catalog)
            if selectedSituationID == nil {
                selectedSituationID = catalog.situations.first?.id
            }
            syncArticleSelection(for: selectedSituationID)
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectSituation(_ id: GuideSituation.ID?) {
        selectedSituationID = id
        syncArticleSelection(for: id)
    }

    func selectArticle(_ id: GuideArticle.ID?) {
        selectedArticleID = id
    }

    private func syncArticleSelection(for situationID: GuideSituation.ID?) {
        guard let catalog else {
            selectedArticleID = nil
            return
        }
        let articles = catalog.articles(for: situationID)
        if let selectedArticleID, articles.contains(where: { $0.id == selectedArticleID }) {
            return
        }
        selectedArticleID = articles.first?.id
    }
}
