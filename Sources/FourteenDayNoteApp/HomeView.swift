import FourteenDayCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var appModel: AppModel
    @Bindable var router: AppRouter
    @Bindable var checklist: PreparednessChecklistModel

    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var plans: [StockpileSchema.Plan]
    @State private var persistenceError: String?

    private let shortcutSituationIDs = [
        "earthquake",
        "blackout",
        "water-outage",
        "flood",
        "first-aid",
        "evacuation",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                    welcomeCard
                    emergencySection
                    preparednessSection
                    offlineNote
                }
                .padding(AppTheme.contentGutter)
                .frame(maxWidth: 880, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(AppTheme.canvas)
            .navigationTitle("ホーム")
        }
        .task { loadPlan() }
        .overlay(alignment: .bottom) {
            if let persistenceError {
                Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.red, in: .capsule)
                    .padding()
            }
        }
    }

    private var welcomeCard: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("14日ノート")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.ochre)
                Text("困った今も、\n備える今日も。")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                Text("通信がなくても、最初の行動と家庭の準備を確認できます。")
                    .font(.body)
                    .foregroundStyle(AppTheme.ivory.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            BrandMark(size: 76)
        }
        .padding(20)
        .background(
            AppTheme.brandGradient,
            in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
        )
        .shadow(color: AppTheme.deepTeal.opacity(0.18), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("14日ノート。困った今も、備える今日も。通信なしで利用できます")
    }

    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "いま困っている",
                subtitle: "選ぶと、最初に確認する記事をすぐ開きます。"
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: 12)],
                spacing: 12
            ) {
                ForEach(shortcutSituationIDs, id: \.self) { situationID in
                    if let situation = appModel.catalog?.situation(id: situationID),
                       let article = appModel.catalog?.emergencyShortcutArticle(for: situationID) {
                        Button {
                            openShortcut(situation: situation, article: article)
                        } label: {
                            EmergencyShortcutCard(situation: situation)
                        }
                        .buttonStyle(PressableScaleButtonStyle())
                        .accessibilityIdentifier("home.emergency.\(situationID)")
                        .accessibilityHint("最優先の記事を開きます")
                    }
                }
            }

            Button {
                appModel.selectSituation(nil)
                router.navigate(to: .guideRoot)
            } label: {
                Label("すべての状況を見る", systemImage: "list.bullet.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityIdentifier("home.allSituations")
        }
    }

    private var preparednessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "平時に備える",
                subtitle: "安全度の採点ではなく、3つの準備項目を確認します。"
            )

            SurfaceCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("最初の10分", systemImage: "checklist")
                            .font(.title3.bold())
                        Spacer()
                        Text("3項目中 \(checklist.state.reviewedCount)項目を確認")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    preparednessButton(
                        title: "人数と7日・14日を確認",
                        detail: householdDetail,
                        isComplete: checklist.state.householdReviewedAt != nil,
                        systemImage: "person.2"
                    ) {
                        router.navigate(to: .preparedness)
                    }

                    Divider()

                    preparednessButton(
                        title: "家に足りない物を選ぶ",
                        detail: stockpileDetail,
                        isComplete: checklist.state.stockpileReviewedAt != nil,
                        systemImage: "shippingbox"
                    ) {
                        router.navigate(to: .preparedness)
                    }

                    Divider()

                    preparednessButton(
                        title: "緊急カードを確認",
                        detail: emergencyCardDetail,
                        isComplete: checklist.state.emergencyCardChoice.isReviewed,
                        systemImage: "person.text.rectangle"
                    ) {
                        router.navigate(to: .emergencyCard)
                    }
                }
            }

            if pendingPurchaseCount > 0 {
                Button {
                    router.navigate(to: .shopping)
                } label: {
                    Label(
                        "買う物を確認（残り\(pendingPurchaseCount)品目）",
                        systemImage: "cart.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var offlineNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(AppTheme.deepTeal)
            Text("ガイド、備蓄、緊急カードは端末内で利用できます。公式サイトを開く操作だけはオンラインです。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func preparednessButton(
        title: String,
        detail: String,
        isComplete: Bool,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : systemImage)
                    .font(.title3)
                    .foregroundStyle(isComplete ? AppTheme.deepTeal : AppTheme.accent)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isComplete ? "確認済み" : "未確認")
    }

    private var primaryPlan: StockpileSchema.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    private var pendingPurchaseCount: Int {
        primaryPlan?.items.count { $0.isShortage && !$0.isPurchased } ?? 0
    }

    private var householdDetail: String {
        guard let primaryPlan else { return "人数と期間を選びます" }
        return "\(primaryPlan.household.totalPeople)人・\(primaryPlan.targetDays.displayName)"
    }

    private var stockpileDetail: String {
        guard let primaryPlan else { return "不足品を選びます" }
        let shortageCount = primaryPlan.items.count(where: \.isShortage)
        if shortageCount == 0 {
            return "不足品はまだ選ばれていません"
        }
        return "不足品\(shortageCount)件・購入待ち\(pendingPurchaseCount)件"
    }

    private var emergencyCardDetail: String {
        switch checklist.state.emergencyCardChoice {
        case .notReviewed:
            "任意。作るか、今回は使わないかを選べます"
        case .prepared:
            "カードを準備済み"
        case .skipped:
            "今回は使わない設定"
        }
    }

    private func openShortcut(situation: GuideSituation, article: GuideArticle) {
        appModel.clearArticleFilters()
        appModel.showsFavoritesOnly = false
        appModel.searchQuery = ""
        appModel.selectSituation(situation.id)
        appModel.selectArticle(article.id, requireDisplayed: false)
        router.navigate(to: .article(situationID: situation.id, articleID: article.id))
    }

    private func loadPlan() {
        do {
            try StockpileStore.loadOrCreatePlan(in: modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "備えの状態を読み込めませんでした。"
        }
    }
}

private struct EmergencyShortcutCard: View {
    let situation: GuideSituation

    var body: some View {
        SurfaceCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                IconWell(systemName: situation.systemImage, tint: AppTheme.coral)
                Text(situation.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("最初の行動を見る")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.coral)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
    }
}
