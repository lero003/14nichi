import FourteenDayCore
import SwiftUI

struct StockpileView: View {
    @Bindable var model: StockpileViewModel
    @Environment(ReadabilitySettings.self) private var readability

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                    StockpileIntroduction()
                    HouseholdInputSection(model: model)
                    StockpileSummary(model: model)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("品目ごとの計画")
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)

                        ForEach($model.entries) { $entry in
                            StockpileItemEditor(
                                entry: $entry,
                                household: model.household,
                                targetDays: model.targetDays
                            )
                        }
                    }
                }
                .padding(AppTheme.contentGutter)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle("備蓄計算")
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

                Text("家族の人数、1人1日あたりの計画量、現在の在庫量から、不足量を端末内で計算します。")
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
            }
        }
    }
}

private struct HouseholdInputSection: View {
    @Bindable var model: StockpileViewModel

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("家族と日数")
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Stepper("大人 \(model.adultCount)人", value: $model.adultCount, in: 0...20)
                Stepper("子ども \(model.childCount)人", value: $model.childCount, in: 0...20)
                Stepper("高齢者 \(model.seniorCount)人", value: $model.seniorCount, in: 0...20)

                Divider()

                Picker("備蓄する日数", selection: $model.targetDays) {
                    ForEach(StockpileTargetDays.allCases) { target in
                        Text(target.displayName).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                Text("合計 \(model.household.totalPeople)人 × \(model.targetDays.displayName)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(
                        "計算対象、合計 \(model.household.totalPeople)人、\(model.targetDays.displayName)"
                    )
            }
        }
    }
}

private struct StockpileSummary: View {
    @Bindable var model: StockpileViewModel

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
        if model.household.totalPeople == 0 {
            return "人数を入力してください"
        }
        if model.configuredItemCount == 0 {
            return "品目の1日量を入力してください"
        }
        if model.shortageItemCount > 0 {
            return "\(model.shortageItemCount)品目に不足があります"
        }
        return "入力済みの品目に不足はありません"
    }

    private var summaryDetail: String {
        if model.household.totalPeople == 0 {
            return "計算には1人以上の人数が必要です。"
        }
        if model.configuredItemCount < model.entries.count {
            return "\(model.entries.count - model.configuredItemCount)品目は1日量が未入力です。"
        }
        return "現在の入力値をもとにした計算結果です。"
    }

    private var summaryIcon: String {
        if model.household.totalPeople == 0 || model.configuredItemCount == 0 {
            return "pencil.circle.fill"
        }
        return model.shortageItemCount > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
    }

    private var summaryColor: Color {
        model.shortageItemCount > 0 ? .orange : .accentColor
    }
}

private struct StockpileItemEditor: View {
    @Binding var entry: StockpileEntry
    let household: HouseholdProfile
    let targetDays: StockpileTargetDays

    private var result: StockpileResult {
        StockpileCalculator.calculate(
            entry: entry,
            household: household,
            targetDays: targetDays
        )
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.name)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        quantityField(
                            title: "1人1日あたり",
                            value: dailyAmountBinding
                        )
                        quantityField(
                            title: "現在の在庫",
                            value: currentAmountBinding
                        )
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        quantityField(
                            title: "1人1日あたり",
                            value: dailyAmountBinding
                        )
                        quantityField(
                            title: "現在の在庫",
                            value: currentAmountBinding
                        )
                    }
                }

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
                .accessibilityLabel("\(entry.name)の\(title)")
                Text(entry.unit)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dailyAmountBinding: Binding<Double> {
        Binding(
            get: { entry.dailyAmountPerPerson },
            set: { entry.dailyAmountPerPerson = sanitized($0) }
        )
    }

    private var currentAmountBinding: Binding<Double> {
        Binding(
            get: { entry.currentAmount },
            set: { entry.currentAmount = sanitized($0) }
        )
    }

    private func sanitized(_ value: Double) -> Double {
        guard value.isFinite, value > 0 else { return 0 }
        return value
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
        ResultMetric(
            title: "必要量",
            value: "\(formatted(result.requiredAmount)) \(result.entry.unit)"
        )
        ResultMetric(
            title: "現在量",
            value: "\(formatted(result.currentAmount)) \(result.entry.unit)"
        )
        if let coveredDays = result.coveredDays {
            ResultMetric(
                title: "現在量の目安",
                value: "約\(formatted(coveredDays))日分"
            )
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
    StockpileView(model: StockpileViewModel())
        .environment(ReadabilitySettings())
}
