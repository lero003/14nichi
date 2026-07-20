import SwiftData
import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel
    let emergencyContainer: ModelContainer?
    @State private var selection: AppSection = .guide

    var body: some View {
        TabView(selection: $selection) {
            Tab("ガイド", systemImage: "book.closed", value: .guide) {
                ArticleBrowserView(model: appModel)
            }

            Tab("備蓄", systemImage: "shippingbox", value: .stockpile) {
                StockpileView()
            }

            Tab("買い物", systemImage: "cart", value: .shopping) {
                ShoppingListView()
            }

            Tab("緊急", systemImage: "person.text.rectangle", value: .emergency) {
                emergencyTab
            }

            Tab("その他", systemImage: "ellipsis.circle", value: .more) {
                MoreView(emergencyContainer: emergencyContainer)
            }
        }
    }

    @ViewBuilder
    private var emergencyTab: some View {
        if let emergencyContainer {
            EmergencyCardView()
                .modelContainer(emergencyContainer)
        } else {
            ContentUnavailableView {
                Label("緊急カードを利用できません", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("個人情報用の保存領域を開けませんでした。アプリを終了して、もう一度開いてください。")
            }
        }
    }
}

private enum AppSection: Hashable {
    case guide
    case stockpile
    case shopping
    case emergency
    case more
}
