import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel
    @State private var stockpileModel = StockpileViewModel()
    @State private var selection: AppSection = .guide

    var body: some View {
        TabView(selection: $selection) {
            Tab("ガイド", systemImage: "book.closed", value: .guide) {
                ArticleBrowserView(model: appModel)
            }

            Tab("備蓄", systemImage: "shippingbox", value: .stockpile) {
                StockpileView(model: stockpileModel)
            }
        }
    }
}

private enum AppSection: Hashable {
    case guide
    case stockpile
}
