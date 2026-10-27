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

        // Simulatorでのスクリーンショット確認用。`--screenshot-route=article/earthquake-first-actions` など。
        if let argument = ProcessInfo.processInfo.arguments.first(
            where: { $0.hasPrefix("--screenshot-route=") }
        ) {
            applyScreenshotRoute(String(argument.dropFirst("--screenshot-route=".count)))
            return
        }

        // 旧スクリーンショット引数との互換。
        if let argument = ProcessInfo.processInfo.arguments.first(
            where: { $0.hasPrefix("--v11-screenshot=") }
        ) {
            switch argument.replacingOccurrences(of: "--v11-screenshot=", with: "") {
            case "earthquake":
                applyScreenshotRoute("article/earthquake-first-actions")
            case "preparedness":
                applyScreenshotRoute("preparedness")
            default:
                break
            }
        }
#endif
    }

#if DEBUG
    /// `guide` / `situation/<id>` / `article/<id>` / `preparedness` / `shopping` / `emergency` / `more`
    private func applyScreenshotRoute(_ route: String) {
        let parts = route.split(separator: "/").map(String.init)
        guard let head = parts.first else { return }

        switch head {
        case "guide":
            appModel.selectSituation(nil)
            appModel.clearArticleFilters()
            router.navigate(to: .guideRoot)
        case "situation":
            guard parts.count > 1,
                  let situation = appModel.catalog?.situation(id: parts[1])
            else { return }
            appModel.selectSituation(situation.id)
            router.navigate(to: .situation(situation.id))
        case "article":
            guard parts.count > 1,
                  let article = appModel.catalog?.article(id: parts[1])
            else { return }
            let situationID = article.situations.first
            appModel.selectSituation(situationID)
            appModel.selectArticle(article.id, requireDisplayed: false)
            router.navigate(
                to: .article(situationID: situationID, articleID: article.id)
            )
        case "preparedness":
            router.navigate(to: .preparedness)
        case "shopping":
            router.navigate(to: .shopping)
        case "emergency":
            router.selectedTab = .emergency
        case "more":
            router.selectedTab = .more
        default:
            break
        }
    }
#endif
}

#if DEBUG
/// iPad Simulatorで、同じブラウザの幅とサイズクラスを実行中に往復させる回帰確認用。
/// 通常起動・Releaseでは表示しない。Duoの実際のpose・セーフエリアの代用にはしない。
struct AdaptiveGuideTestHost: View {
    let model: AppModel
    @State private var router = AppRouter()
    @State private var compact = true
    @State private var appliedRoute = false

    var body: some View {
        ArticleBrowserView(model: model, router: router)
            .environment(\.horizontalSizeClass, compact ? .compact : .regular)
            .frame(maxWidth: compact ? 390 : .infinity)
            .frame(maxWidth: .infinity)
            .safeAreaInset(edge: .bottom) {
                Button(compact ? "検証: 広い画面へ" : "検証: 狭い画面へ") {
                    compact.toggle()
                }
                .accessibilityIdentifier("testing.toggleGuideWidth")
                .buttonStyle(.bordered)
                .padding(8)
                .background(.bar)
            }
            .task {
                guard !appliedRoute else { return }
                appliedRoute = true
                if let argument = ProcessInfo.processInfo.arguments.first(where: {
                    $0.hasPrefix("--screenshot-route=article/")
                }), let article = model.catalog?.article(id: String(argument.dropFirst("--screenshot-route=article/".count))) {
                    model.selectSituation(article.situations.first)
                    model.selectArticle(article.id, requireDisplayed: false)
                    router.navigate(to: .article(situationID: article.situations.first, articleID: article.id))
                }
            }
    }
}
#endif
