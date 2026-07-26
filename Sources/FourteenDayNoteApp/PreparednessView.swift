import SwiftUI

struct PreparednessView: View {
    @Bindable var router: AppRouter
    @Bindable var checklist: PreparednessChecklistModel

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.preparednessPath) {
            StockpileView(router: router, checklist: checklist)
                .navigationDestination(for: PreparednessRoute.self) { route in
                    switch route {
                    case .shopping:
                        ShoppingListView()
                    }
                }
        }
    }
}
