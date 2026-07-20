import FourteenDayCore
import SwiftData
import SwiftUI

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var plans: [StockpileSchema.Plan]
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let plan = primaryPlan {
                    content(for: plan)
                } else if let persistenceError {
                    ContentUnavailableView {
                        Label("買い物リストを読み込めません", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(persistenceError)
                    } actions: {
                        Button("もう一度試す", action: loadPlan)
                    }
                } else {
                    ProgressView("買い物リストを準備中…")
                }
            }
            .navigationTitle("買い物リスト")
        }
        .task { loadPlan() }
    }

    private var primaryPlan: StockpileSchema.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    @ViewBuilder
    private func content(for plan: StockpileSchema.Plan) -> some View {
        let rows = shoppingRows(for: plan)
        let selectedCount = plan.items.count(where: \.isShortage)

        if selectedCount == 0 {
            ContentUnavailableView(
                "足りないものは未選択です",
                systemImage: "checklist",
                description: Text("備蓄タブで必要量を確認し、家に足りない品目だけをチェックしてください。")
            )
        } else if rows.isEmpty {
            ContentUnavailableView(
                "買い物は完了です",
                systemImage: "checkmark.circle",
                description: Text("チェックした品目はすべて購入済みです。")
            )
        } else {
            shoppingList(rows: rows, plan: plan)
        }
    }

    private func shoppingList(rows: [ShoppingRow], plan: StockpileSchema.Plan) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("買うものは \(rows.count)品目", systemImage: "cart.fill")
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                        Text("数量がある品目は \(plan.household.totalPeople)人 × \(plan.targetDays.displayName) の目安です。チェックリスト品目は必要数を家庭で決めてください。買った品目は一覧から外れます。")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(rows) { row in
                    ShoppingItemCard(row: row) { markPurchased(row.item) }
                }
            }
            .padding(AppTheme.contentGutter)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .overlay(alignment: .bottom) { persistenceErrorOverlay }
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

    private func shoppingRows(for plan: StockpileSchema.Plan) -> [ShoppingRow] {
        plan.items
            .filter { $0.isShortage && !$0.isPurchased }
            .sorted {
                $0.sortOrder == $1.sortOrder ? $0.stableID < $1.stableID : $0.sortOrder < $1.sortOrder
            }
            .compactMap { item in
                guard let recommendation = StockpileRecommendations.recommendation(id: item.stableID) else {
                    return nil
                }
                if recommendation.isQuantified {
                    let result = StockpileCalculator.calculate(
                        entry: recommendation.entry(),
                        household: plan.household,
                        targetDays: plan.targetDays
                    )
                    return ShoppingRow(
                        item: item,
                        recommendation: recommendation,
                        quantifiedResult: result
                    )
                }
                return ShoppingRow(
                    item: item,
                    recommendation: recommendation,
                    quantifiedResult: nil
                )
            }
    }

    private func loadPlan() {
        do {
            try StockpileStore.loadOrCreatePlan(in: modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "端末内の備蓄データを読み込めませんでした。\(error.localizedDescription)"
        }
    }

    private func markPurchased(_ item: StockpileSchema.Item) {
        do {
            try StockpileStore.markPurchased(item, in: modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "購入済みとして保存できませんでした。\(error.localizedDescription)"
        }
    }
}

private struct ShoppingRow: Identifiable {
    let item: StockpileSchema.Item
    let recommendation: StockpileRecommendation
    let quantifiedResult: StockpileResult?
    var id: String { item.stableID }
}

private struct ShoppingItemCard: View {
    let row: ShoppingRow
    let markPurchased: () -> Void

    var body: some View {
        SurfaceCard {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(row.item.name)
                        .font(.title3.weight(.semibold))
                    if let result = row.quantifiedResult {
                        Text("\(formatted(result.requiredAmount)) \(result.entry.unit)")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    } else {
                        Text(row.recommendation.example)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                Button("買った", systemImage: "checkmark.circle", action: markPurchased)
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("購入済みにして買い物リストから外します")
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

#Preview {
    ShoppingListView()
        .environment(ReadabilitySettings())
        .modelContainer(for: StockpileSchema.models, inMemory: true)
}
