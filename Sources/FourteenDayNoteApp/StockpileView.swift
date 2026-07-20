import FourteenDayCore
import SwiftData
import SwiftUI

struct StockpileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var plans: [StockpileSchemaV1.Plan]
    @State private var persistenceError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let plan = primaryPlan {
                    stockpileContent(plan: plan)
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
            .navigationTitle("備蓄計算")
        }
        .task {
            loadPlan()
        }
    }

    private var primaryPlan: StockpileSchemaV1.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    private func stockpileContent(plan: StockpileSchemaV1.Plan) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                StockpileIntroduction()
                HouseholdInputSection(plan: plan, save: saveChanges)
                StockpileSummary(plan: plan)
                ChecklistProgress(plan: plan)

                VStack(alignment: .leading, spacing: 12) {
                    Text("品目ごとの計画")
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)

                    ForEach(sortedItems(for: plan)) { item in
                        StockpileItemEditor(
                            item: item,
                            household: plan.household,
                            targetDays: plan.targetDays,
                            save: saveChanges
                        )
                    }
                }
            }
            .padding(AppTheme.contentGutter)
            .frame(maxWidth: 820, alignment: .leading)
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

    private func sortedItems(for plan: StockpileSchemaV1.Plan) -> [StockpileSchemaV1.Item] {
        plan.items.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.stableID < $1.stableID
            }
            return $0.sortOrder < $1.sortOrder
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

private struct StockpileIntroduction: View {
    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("7日・14日の必要量を確認", systemImage: "calendar.badge.clock")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)

                Text("家族の人数、1人1日あたりの計画量、現在の在庫量から、不足量を端末内で計算・保存します。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    "1日量には初期値を入れていません。公的な案内や家庭の事情に合わせて入力してください。",
                    systemImage: "info.circle.fill"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Label("入力内容はこの端末内に保存されます", systemImage: "internaldrive.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HouseholdInputSection: View {
    @Bindable var plan: StockpileSchemaV1.Plan
    let save: () -> Void

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("家族と日数")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Stepper("大人 \(plan.adultCount)人", value: countBinding(\.adultCount), in: 0...20)
                Stepper("子ども \(plan.childCount)人", value: countBinding(\.childCount), in: 0...20)
                Stepper("高齢者 \(plan.seniorCount)人", value: countBinding(\.seniorCount), in: 0...20)

                Divider()

                Picker("備蓄する日数", selection: targetDaysBinding) {
                    ForEach(StockpileTargetDays.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                Text("合計 \(plan.household.totalPeople)人 × \(plan.targetDays.displayName)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(
                        "計算対象、合計 \(plan.household.totalPeople)人、\(plan.targetDays.displayName)"
                    )
            }
        }
    }

    private func countBinding(_ keyPath: ReferenceWritableKeyPath<StockpileSchemaV1.Plan, Int>) -> Binding<Int> {
        Binding(
            get: { plan[keyPath: keyPath] },
            set: {
                plan[keyPath: keyPath] = max(0, $0)
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

private struct StockpileSummary: View {
    let plan: StockpileSchemaV1.Plan

    private var results: [StockpileResult] {
        plan.items.map {
            StockpileCalculator.calculate(
                entry: $0.calculationEntry,
                household: plan.household,
                targetDays: plan.targetDays
            )
        }
    }

    private var configuredItemCount: Int {
        results.count(where: \.isConfigured)
    }

    private var shortageItemCount: Int {
        results.count(where: \.hasShortage)
    }

    var body: some View {
        SurfaceCard {
            Label {
                VStack(alignment: .leading, spacing: 5) {
                    Text(summaryTitle)
                        .font(.headline)
                    Text(summaryDetail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: summaryIcon)
                    .foregroundStyle(summaryColor)
                    .imageScale(.large)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var summaryTitle: String {
        if plan.household.totalPeople == 0 {
            return "人数を入力してください"
        }
        if configuredItemCount == 0 {
            return "品目の1日量を入力してください"
        }
        if shortageItemCount > 0 {
            return "\(shortageItemCount)品目に不足があります"
        }
        return "入力済みの品目に不足はありません"
    }

    private var summaryDetail: String {
        if plan.household.totalPeople == 0 {
            return "計算には1人以上の人数が必要です。"
        }
        if configuredItemCount < plan.items.count {
            return "\(plan.items.count - configuredItemCount)品目は1日量が未入力です。"
        }
        return "現在の入力値をもとにした計算結果です。"
    }

    private var summaryIcon: String {
        if plan.household.totalPeople == 0 || configuredItemCount == 0 {
            return "pencil.circle.fill"
        }
        return shortageItemCount > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
    }

    private var summaryColor: Color {
        shortageItemCount > 0 ? .orange : .accentColor
    }
}

private struct ChecklistProgress: View {
    let plan: StockpileSchemaV1.Plan

    private var preparedCount: Int {
        plan.items.count(where: \.isPrepared)
    }

    private var deadlineWarningCount: Int {
        plan.items.count {
            switch StockpileExpirationStatus.evaluate(expirationDate: $0.expirationDate) {
            case .expired, .dueSoon:
                true
            case .none, .scheduled:
                false
            }
        }
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("チェックリスト", systemImage: "checklist")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text("準備済み \(preparedCount) / \(plan.items.count)品目")
                    .font(.body.weight(.semibold))

                if deadlineWarningCount > 0 {
                    Label("期限切れ、または30日以内の品目が\(deadlineWarningCount)件あります", systemImage: "calendar.badge.exclamationmark")
                        .font(.callout)
                        .foregroundStyle(.orange)
                } else {
                    Text("期限を設定すると、期限切れや30日以内の品目をここで確認できます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct StockpileItemEditor: View {
    @Bindable var item: StockpileSchemaV1.Item
    let household: HouseholdProfile
    let targetDays: StockpileTargetDays
    let save: () -> Void

    private var result: StockpileResult {
        StockpileCalculator.calculate(
            entry: item.calculationEntry,
            household: household,
            targetDays: targetDays
        )
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(item.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    Toggle("準備済み", isOn: preparedBinding)
#if os(macOS)
                        .toggleStyle(.checkbox)
#endif
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        quantityField(title: "1人1日あたり", value: dailyAmountBinding)
                        quantityField(title: "現在の在庫", value: currentAmountBinding)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        quantityField(title: "1人1日あたり", value: dailyAmountBinding)
                        quantityField(title: "現在の在庫", value: currentAmountBinding)
                    }
                }

                ExpirationEditor(item: item, save: save)

                Divider()

                if result.isConfigured {
                    StockpileResultView(result: result)
                } else {
                    Label("人数と1日量を入力すると必要量を計算します", systemImage: "pencil")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func quantityField(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                TextField(
                    title,
                    value: value,
                    format: .number.precision(.fractionLength(0...2))
                )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .accessibilityLabel("\(item.name)の\(title)")
                Text(item.unit)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var preparedBinding: Binding<Bool> {
        Binding(
            get: { item.isPrepared },
            set: {
                item.isPrepared = $0
                save()
            }
        )
    }

    private var dailyAmountBinding: Binding<Double> {
        Binding(
            get: { item.dailyAmountPerPerson },
            set: {
                item.dailyAmountPerPerson = sanitized($0)
                save()
            }
        )
    }

    private var currentAmountBinding: Binding<Double> {
        Binding(
            get: { item.currentAmount },
            set: {
                item.currentAmount = sanitized($0)
                save()
            }
        )
    }

    private func sanitized(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return 0 }
        return value
    }
}

private struct ExpirationEditor: View {
    @Bindable var item: StockpileSchemaV1.Item
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("期限を設定", isOn: hasExpirationBinding)

            if item.expirationDate != nil {
                DatePicker(
                    "期限日",
                    selection: expirationDateBinding,
                    displayedComponents: .date
                )
                ExpirationStatusLabel(status: expirationStatus)
            }
        }
    }

    private var hasExpirationBinding: Binding<Bool> {
        Binding(
            get: { item.expirationDate != nil },
            set: { hasExpiration in
                item.expirationDate = hasExpiration
                    ? Calendar.current.startOfDay(for: .now)
                    : nil
                save()
            }
        )
    }

    private var expirationDateBinding: Binding<Date> {
        Binding(
            get: { item.expirationDate ?? Calendar.current.startOfDay(for: .now) },
            set: {
                item.expirationDate = $0
                save()
            }
        )
    }

    private var expirationStatus: StockpileExpirationStatus {
        StockpileExpirationStatus.evaluate(expirationDate: item.expirationDate)
    }
}

private struct ExpirationStatusLabel: View {
    let status: StockpileExpirationStatus

    var body: some View {
        Label(labelText, systemImage: systemImage)
            .font(.callout.weight(.medium))
            .foregroundStyle(color)
    }

    private var labelText: String {
        switch status {
        case .none:
            "期限なし"
        case .expired(let daysAgo):
            daysAgo == 0 ? "今日が期限です" : "期限切れ（\(daysAgo)日前）"
        case .dueSoon(let daysRemaining):
            daysRemaining == 0 ? "今日が期限です" : "期限まで\(daysRemaining)日"
        case .scheduled(let daysRemaining):
            "期限まで\(daysRemaining)日"
        }
    }

    private var systemImage: String {
        switch status {
        case .expired:
            "exclamationmark.triangle.fill"
        case .dueSoon:
            "calendar.badge.exclamationmark"
        case .none, .scheduled:
            "calendar"
        }
    }

    private var color: Color {
        switch status {
        case .expired:
            .red
        case .dueSoon:
            .orange
        case .none, .scheduled:
            .secondary
        }
    }
}

private struct StockpileResultView: View {
    let result: StockpileResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { metrics }
                VStack(alignment: .leading, spacing: 10) { metrics }
            }

            Label(
                result.hasShortage
                    ? "不足 \(formatted(result.shortageAmount)) \(result.entry.unit)"
                    : "この入力では不足なし",
                systemImage: result.hasShortage
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(result.hasShortage ? .orange : .green)
            .accessibilityLabel(statusAccessibilityLabel)
        }
    }

    @ViewBuilder
    private var metrics: some View {
        ResultMetric(title: "必要量", value: "\(formatted(result.requiredAmount)) \(result.entry.unit)")
        ResultMetric(title: "現在量", value: "\(formatted(result.currentAmount)) \(result.entry.unit)")
        if let coveredDays = result.coveredDays {
            ResultMetric(title: "現在量の目安", value: "約\(formatted(coveredDays))日分")
        }
    }

    private var statusAccessibilityLabel: String {
        if result.hasShortage {
            return "不足量、\(formatted(result.shortageAmount)) \(result.entry.unit)"
        }
        return "この入力では不足なし"
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

private struct ResultMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StockpileView()
        .environment(ReadabilitySettings())
        .modelContainer(for: StockpileSchemaV1.models, inMemory: true)
}
