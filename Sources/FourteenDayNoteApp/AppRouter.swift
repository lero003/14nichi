import FourteenDayCore
import Observation

enum AppTab: Hashable {
    case home
    case guide
    case preparedness
    case emergency
    case more
}

enum GuideRoute: Hashable {
    case situation(GuideSituation.ID)
    case article(GuideArticle.ID)
}

enum PreparednessRoute: Hashable {
    case shopping
}

enum AppRoute: Hashable {
    case home
    case guideRoot
    case situation(GuideSituation.ID)
    case article(situationID: GuideSituation.ID?, articleID: GuideArticle.ID)
    case preparedness
    case shopping
    case emergencyCard
    case more
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var guidePath: [GuideRoute] = []
    var preparednessPath: [PreparednessRoute] = []

    func navigate(to route: AppRoute) {
        switch route {
        case .home:
            selectedTab = .home

        case .guideRoot:
            guidePath = []
            selectedTab = .guide

        case .situation(let situationID):
            guidePath = [.situation(situationID)]
            selectedTab = .guide

        case .article(let situationID, let articleID):
            if let situationID {
                guidePath = [.situation(situationID), .article(articleID)]
            } else {
                guidePath = [.article(articleID)]
            }
            selectedTab = .guide

        case .preparedness:
            preparednessPath = []
            selectedTab = .preparedness

        case .shopping:
            preparednessPath = [.shopping]
            selectedTab = .preparedness

        case .emergencyCard:
            selectedTab = .emergency

        case .more:
            selectedTab = .more
        }
    }
}

@MainActor
@Observable
final class PreparednessChecklistModel {
    private(set) var state: PreparednessChecklistState
    private let store: PreparednessChecklistStore

    init(store: PreparednessChecklistStore = PreparednessChecklistStore()) {
        self.store = store
        state = store.load()
    }

    func markHouseholdReviewed() {
        state = store.markHouseholdReviewed()
    }

    func markStockpileReviewed() {
        state = store.markStockpileReviewed()
    }

    func setEmergencyCardChoice(_ choice: EmergencyCardPreparationChoice) {
        state = store.setEmergencyCardChoice(choice)
    }
}
