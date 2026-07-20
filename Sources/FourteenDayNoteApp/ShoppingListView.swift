import FourteenDayCore
import SwiftData
import SwiftUI

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var plans: [StockpileSchemaV1.Plan]
    @State private var persistenceError: String?
    @State private var pendingItemID: String?

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
        .task {
            loadPlan()
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationIsPresented,
            titleVisibility: .visible
        ) {
            Button("購入分を在庫へ反映") {
                applyPendingItem()
            }
            Button("キャンセル", role: .cancel) {
                pendingItemID = nil
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var primaryPlan: StockpileSchemaV1.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    @ViewBuilder
    private func content(for plan: StockpileSchemaV1.Plan) -> some View {
        let rows = shoppingRows(for: plan)

        if plan.household.totalPeople == 0 {
            ContentUnavailableView(
                "家族の人数が未入力です",
                systemImage: "person.2",
                description: Text("備蓄タブで1人以上を入力すると、買い物リストを計算できます。")
            )
        } else if configuredItemCount(for: plan) == 0 {
            ContentUnavailableView(
                "1日量が未入力です",
                systemImage: "pencil.and.list.clipboard",
                description: Text("備蓄タブで品目の1人1日量を入力してください。")
            )
        } else if rows.isEmpty {
            ContentUnavailableView(
                "不足品目はありません",
                systemImage: "checkmark.circle",
                description: Text("現在の人数・日数・在庫量では、入力済みの品目に不足はありません。")
            )
        } else {
            shoppingList(rows: rows, plan: plan)
        }
    }

    private func shoppingList(
        rows: [ShoppingRow],
        plan: StockpileSchemaV1.Plan
    ) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("不足しているもの", systemImage: "cart.fill")
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)

                        Text("\(plan.household.totalPeople)人 × \(plan.targetDays.displayName)の計画で、\(rows.count)品目が不足しています。")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("購入後に「購入分を在庫へ反映」を押すと、現在量を必要量まで更新し、この一覧から外します。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ForEach(rows) { row in
                    ShoppingItemCard(row: row) {
                        pendingItemID = row.id
                    }
                }
            }
            .padding(AppTheme.contentGutter)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .overlay(alignment: .bottom) {
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
    }

    private func shoppingRows(for plan: StockpileSchemaV1.Plan) -> [ShoppingRow] {
        let items = plan.items.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.stableID < $1.stableID
            }
            return $0.sortOrder < $1.sortOrder
        }
        let results = StockpileShoppingList.shortages(
            entries: items.map(\.calculationEntry),
            household: plan.household,
            targetDays: plan.targetDays
        )
        let itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.stableID, $0) })

        return results.compactMap { result in
            guard let item = itemsByID[result.id] else { return nil }
            return ShoppingRow(item: item, result: result)
        }
    }

    private func configuredItemCount(for plan: StockpileSchemaV1.Plan) -> Int {
        plan.items.count {
            StockpileCalculator.calculate(
                entry: $0.calculationEntry,
                household: plan.household,
                targetDays: plan.targetDays
            ).isConfigured
        }
    }

    private var pendingRow: ShoppingRow? {
        guard let plan = primaryPlan, let pendingItemID else { return nil }
        return shoppingRows(for: plan).first { $0.id == pendingItemID }
    }

    private var confirmationIsPresented: Binding<Bool> {
        Binding(
            get: { pendingItemID != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingItemID = nil
                }
            }
        )
    }

    private var confirmationTitle: String {
        guard let pendingRow else { return "在庫へ反映しますか？" }
        return "\(pendingRow.item.name)を在庫へ反映しますか？"
    }

    private var confirmationMessage: String {
        guard let pendingRow else { return "現在量を更新します。" }
        return "不足分 \(formatted(pendingRow.result.shortageAmount)) \(pendingRow.item.unit)を現在量へ反映し、準備済みにします。元に戻す場合は備蓄タブで現在量を編集してください。"
    }

    private func loadPlan() {
        do {
            try StockpileStore.loadOrCreatePlan(in: modelContext)
            persistenceError = nil
        } catch {
            persistenceError = "端末内の備蓄データを読み込めませんでした。\(error.localizedDescription)"
        }
    }

    private func applyPendingItem() {
        defer { pendingItemID = nil }
        guard let plan = primaryPlan, let pendingRow else { return }

        do {
            try StockpileStore.applyShortageToInventory(
                for: pendingRow.item,
                household: plan.household,
                targetDays: plan.targetDays,
                in: modelContext
            )
            persistenceError = nil
        } catch {
            persistenceError = "購入分を在庫へ反映できませんでした。\(error.localizedDescription)"
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

private struct ShoppingRow: Identifiable {
    let item: StockpileSchemaV1.Item
    let result: StockpileResult

    var id: String { item.stableID }
}

private struct ShoppingItemCard: View {
    let row: ShoppingRow
    let applyToInventory: () -> Void

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(row.item.name)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { metrics }
                    VStack(alignment: .leading, spacing: 10) { metrics }
                }

                Button("購入分を在庫へ反映", systemImage: "checkmark.circle", action: applyToInventory)
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("不足分を現在の在庫量に加え、買い物リストから外します")
            }
        }
    }

    @ViewBuilder
    private var metrics: some View {
        ShoppingMetric(
            title: "買う量",
            value: "\(formatted(row.result.shortageAmount)) \(row.item.unit)",
            emphasized: true
        )
        ShoppingMetric(
            title: "現在量",
            value: "\(formatted(row.result.currentAmount)) \(row.item.unit)"
        )
        ShoppingMetric(
            title: "必要量",
            value: "\(formatted(row.result.requiredAmount)) \(row.item.unit)"
        )
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

private struct ShoppingMetric: View {
    let title: String
    let value: String
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(emphasized ? .bold : .semibold))
                .foregroundStyle(emphasized ? .orange : .primary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ShoppingListView()
        .environment(ReadabilitySettings())
        .modelContainer(for: StockpileSchemaV1.models, inMemory: true)
}
