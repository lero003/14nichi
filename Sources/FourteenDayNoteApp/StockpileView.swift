import FourteenDayCore
import SwiftData
import SwiftUI

struct StockpileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var plans: [StockpileSchema.Plan]
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let plan = primaryPlan {
                    content(plan: plan)
                } else if let persistenceError {
                    ContentUnavailableView {
                        Label("備蓄データを読み込めません", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(persistenceError)
                    } actions: {
                        Button("もう一度試す", action: loadPlan)
                    }
                } else {
                    ProgressView("備蓄データを準備中…")
                }
            }
            .navigationTitle("備蓄の目安")
        }
        .task { loadPlan() }
    }

    private var primaryPlan: StockpileSchema.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    private func content(plan: StockpileSchema.Plan) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                introduction
                HouseholdSelection(plan: plan, save: saveChanges)
                SelectionSummary(plan: plan)

                VStack(alignment: .leading, spacing: 12) {
                    Text("必要量の目安")
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("家に足りないものだけチェックしてください。チェックした品目が買い物タブに表示されます。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(sortedItems(for: plan)) { item in
                        if let recommendation = StockpileRecommendations.recommendation(id: item.stableID) {
                            RecommendationCard(
                                item: item,
                                recommendation: recommendation,
                                household: plan.household,
                                targetDays: plan.targetDays,
                                save: saveChanges
                            )
                        }
                    }
                }
            }
            .padding(AppTheme.contentGutter)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .overlay(alignment: .bottom) { persistenceErrorOverlay }
    }

    private var introduction: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("人数と期間を選ぶだけ", systemImage: "sparkles")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)

                Text("水・食料・携帯トイレの大まかな必要量を自動で計算します。在庫数や1日量の入力は必要ありません。")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                Label("表示する数量は公的情報をもとにした一般的な目安です。年齢、健康状態、食事制限などに合わせて調整してください。", systemImage: "info.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var persistenceErrorOverlay: some View {
        if let persistenceError {
            Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.red, in: .capsule)
                .padding()
                .accessibilityElement(children: .combine)
        }
    }

    private func sortedItems(for plan: StockpileSchema.Plan) -> [StockpileSchema.Item] {
        plan.items.sorted {
            $0.sortOrder == $1.sortOrder ? $0.stableID < $1.stableID : $0.sortOrder < $1.sortOrder
        }
    }

    private func loadPlan() {
        do {
            try StockpileStore.loadOrCreatePlan(in: modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "端末内への保存を開始できませんでした。\(error.localizedDescription)"
        }
    }

    private func saveChanges() {
        do {
            try StockpileStore.save(modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "変更を保存できませんでした。\(error.localizedDescription)"
        }
    }
}

private struct HouseholdSelection: View {
    @Bindable var plan: StockpileSchema.Plan
    let save: () -> Void

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("何人で、何日分？")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Stepper("人数　\(plan.household.totalPeople)人", value: peopleBinding, in: 1...20)
                    .font(.headline)

                Picker("備える期間", selection: targetDaysBinding) {
                    ForEach(StockpileTargetDays.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                Text("\(plan.household.totalPeople)人 × \(plan.targetDays.displayName)で計算")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(plan.household.totalPeople)人、\(plan.targetDays.displayName)で計算")
            }
        }
    }

    private var peopleBinding: Binding<Int> {
        Binding(
            get: { max(1, plan.household.totalPeople) },
            set: { newValue in
                plan.adultCount = max(1, newValue)
                plan.childCount = 0
                plan.seniorCount = 0
                save()
            }
        )
    }

    private var targetDaysBinding: Binding<StockpileTargetDays> {
        Binding(
            get: { plan.targetDays },
            set: {
                plan.targetDays = $0
                save()
            }
        )
    }
}

private struct SelectionSummary: View {
    let plan: StockpileSchema.Plan

    private var shortageCount: Int { plan.items.count(where: \.isShortage) }
    private var purchasedCount: Int { plan.items.count { $0.isShortage && $0.isPurchased } }

    var body: some View {
        SurfaceCard {
            Label {
                VStack(alignment: .leading, spacing: 5) {
                    Text(shortageCount == 0 ? "足りないものを選んでください" : "買い物に \(shortageCount - purchasedCount)品目")
                        .font(.headline)
                    Text(shortageCount == 0 ? "必要量を見て、家に足りない品目だけをチェックします。" : "購入済み \(purchasedCount)品目。残りは買い物タブで確認できます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: shortageCount == 0 ? "checklist" : "cart.fill")
                    .foregroundStyle(.tint)
                    .imageScale(.large)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct RecommendationCard: View {
    @Bindable var item: StockpileSchema.Item
    let recommendation: StockpileRecommendation
    let household: HouseholdProfile
    let targetDays: StockpileTargetDays
    let save: () -> Void

    private var result: StockpileResult {
        StockpileCalculator.calculate(
            entry: recommendation.entry(),
            household: household,
            targetDays: targetDays
        )
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(recommendation.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 12)
                    Text("\(formatted(result.requiredAmount)) \(recommendation.unit)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.tint)
                }

                Text(recommendation.example)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("家に足りない", isOn: shortageBinding)
                    .font(.headline)

                if item.isShortage {
                    Label(
                        item.isPurchased ? "購入済み" : "買い物リストに表示中",
                        systemImage: item.isPurchased ? "checkmark.circle.fill" : "cart.fill"
                    )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(item.isPurchased ? .green : .orange)
                }

                Divider()

                Link(destination: recommendation.source.url) {
                    Label("目安の根拠を確認（オンライン）", systemImage: "arrow.up.right.square")
                }
                .font(.callout)

                Text("\(recommendation.source.publisher)・確認日 \(recommendation.source.accessedAt)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortageBinding: Binding<Bool> {
        Binding(
            get: { item.isShortage },
            set: { isShortage in
                item.isShortage = isShortage
                item.isPurchased = false
                save()
            }
        )
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

#Preview {
    StockpileView()
        .environment(ReadabilitySettings())
        .modelContainer(for: StockpileSchema.models, inMemory: true)
}
