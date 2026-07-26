import Foundation
import SwiftData
import SwiftUI

struct MainTabView: View {
    @Bindable var appModel: AppModel
    let emergencyContainer: ModelContainer?
    @State private var router = AppRouter()
    @State private var checklist = PreparednessChecklistModel()
    @State private var appliedDebugLaunchRoute = false

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("ホーム", systemImage: "house", value: .home) {
                HomeView(
                    appModel: appModel,
                    router: router,
                    checklist: checklist
                )
            }

            Tab("ガイド", systemImage: "book.closed", value: .guide) {
                ArticleBrowserView(model: appModel, router: router)
            }

            Tab("備え", systemImage: "shippingbox", value: .preparedness) {
                PreparednessView(router: router, checklist: checklist)
            }

            Tab("緊急", systemImage: "person.text.rectangle", value: .emergency) {
                emergencyTab
            }

            Tab("その他", systemImage: "ellipsis.circle", value: .more) {
                MoreView(emergencyContainer: emergencyContainer)
            }
        }
        .tint(AppTheme.accent)
        .task {
            applyDebugLaunchRouteIfNeeded()
        }
    }

    @ViewBuilder
    private var emergencyTab: some View {
        if let emergencyContainer {
            EmergencyCardView(checklist: checklist)
                .modelContainer(emergencyContainer)
        } else {
            ContentUnavailableView {
                Label("緊急カードを利用できません", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("個人情報用の保存領域を開けませんでした。アプリを終了して、もう一度開いてください。")
            }
        }
    }

    private func applyDebugLaunchRouteIfNeeded() {
#if DEBUG
        guard appliedDebugLaunchRoute == false else { return }
        appliedDebugLaunchRoute = true
        guard let argument = ProcessInfo.processInfo.arguments.first(
            where: { $0.hasPrefix("--v11-screenshot=") }
        ) else {
            return
        }

        switch argument.replacingOccurrences(of: "--v11-screenshot=", with: "") {
        case "earthquake":
            guard let article = appModel.catalog?.emergencyShortcutArticle(for: "earthquake") else {
                return
            }
            appModel.selectSituation("earthquake")
            appModel.selectArticle(article.id, requireDisplayed: false)
            router.navigate(
                to: .article(
                    situationID: "earthquake",
                    articleID: article.id
                )
            )
        case "preparedness":
            router.navigate(to: .preparedness)
        default:
            break
        }
#endif
    }
}
