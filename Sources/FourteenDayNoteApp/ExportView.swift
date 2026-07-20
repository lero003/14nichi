import FourteenDayCore
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ExportView: View {
    @Environment(\.modelContext) private var stockpileContext
    @Environment(ReadabilitySettings.self) private var readability

    let emergencyContainer: ModelContainer?

    @Query private var plans: [StockpileSchemaV1.Plan]
    @State private var selection = ExportSelection.privacySafeDefault
    @State private var emergencyCard = EmergencyCardSnapshot()
    @State private var acknowledgedPersonalData = false
    @State private var previewText = ""
    @State private var statusMessage: String?
    @State private var isWorking = false
    @State private var authenticator = LocalAuthenticationService()
    @State private var protection = EmergencyCardProtectionStore().load()
#if os(iOS)
    @State private var sharePayload: SharePayload?
#endif

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("紙やファイルに残す項目を選んでから生成します。個人情報は既定でオフです。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("緊急カード") {
                    Toggle("表示名", isOn: $selection.includeDisplayName)
                    Toggle("緊急連絡先", isOn: $selection.includeContacts)
                    Toggle("集合場所", isOn: $selection.includeMeetingPlace)
                    Toggle("避難予定場所", isOn: $selection.includeEvacuationPlace)
                    Toggle("アレルギー", isOn: $selection.includeAllergies)
                    Toggle("常用薬", isOn: $selection.includeMedications)
                    Toggle("注意メモ", isOn: $selection.includeNotes)
                }

                Section("備蓄") {
                    Toggle("家族構成と計画日数", isOn: $selection.includeStockpileHousehold)
                    Toggle("チェックリスト（必要量・在庫・不足）", isOn: $selection.includeStockpileChecklist)
                }

                if selection.includesPersonalInformation {
                    Section("出力前の確認") {
                        Text("選択した項目には個人情報が含まれます。印刷物や共有ファイルは第三者が読める場所に残る可能性があります。生成後の管理は利用者の責任です。")
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        Toggle("内容を理解し、この端末で出力します", isOn: $acknowledgedPersonalData)
                    }
                }

                Section("プレビュー") {
                    if selection.hasAnySelection == false {
                        Text("項目を選択するとプレビューが表示されます。")
                            .foregroundStyle(.secondary)
                    } else if canGenerate == false {
                        Text("個人情報を含む出力には、上の確認が必要です。")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(previewText)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Section {
                    Button {
                        Task { await generateAndShare() }
                    } label: {
                        if isWorking {
                            ProgressView()
                        } else {
                            Label("PDFを生成して共有/印刷", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(canGenerate == false || isWorking)

#if os(macOS)
                    Button {
                        Task { await generateAndPrint() }
                    } label: {
                        Label("PDFを生成して印刷…", systemImage: "printer")
                    }
                    .disabled(canGenerate == false || isWorking)
#endif
                } footer: {
                    Text("ファイル名は個人情報を含まない固定名（\(ExportFileName.pdf)）です。一時ファイルは共有後に削除します。")
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("PDF・印刷")
            .onChange(of: selection) { _, _ in
                refreshPreview()
            }
            .onChange(of: acknowledgedPersonalData) { _, _ in
                refreshPreview()
            }
            .task {
                loadSources()
                refreshPreview()
            }
#if os(iOS)
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: [payload.url])
                    .onDisappear {
                        cleanup(url: payload.url)
                    }
            }
#endif
        }
        .privacyShield(enabled: selection.includesPersonalInformation)
    }

    private var canGenerate: Bool {
        guard selection.hasAnySelection else { return false }
        if selection.includesPersonalInformation {
            return acknowledgedPersonalData
        }
        return true
    }

    private var primaryPlan: StockpileSchemaV1.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    private func loadSources() {
        if let emergencyContainer {
            let context = ModelContext(emergencyContainer)
            if let card = try? EmergencyCardStore.loadOrCreateCard(in: context) {
                emergencyCard = card.snapshot
            }
        }
        if primaryPlan == nil {
            _ = try? StockpileStore.loadOrCreatePlan(in: stockpileContext)
        }
        protection = EmergencyCardProtectionStore().load()
    }

    private func makeDocument() -> ExportDocument {
        ExportDocument(
            selection: selection,
            emergencyCard: emergencyCard,
            stockpile: makeStockpileSnapshot()
        )
    }

    private func makeStockpileSnapshot() -> ExportStockpileSnapshot? {
        guard let plan = primaryPlan else { return nil }
        let household = plan.household
        let items = plan.items.sorted {
            if $0.sortOrder == $1.sortOrder { return $0.stableID < $1.stableID }
            return $0.sortOrder < $1.sortOrder
        }
        .map { item in
            let result = StockpileCalculator.calculate(
                entry: item.calculationEntry,
                household: household,
                targetDays: plan.targetDays
            )
            let status = StockpileExpirationStatus.evaluate(expirationDate: item.expirationDate)
            return ExportStockpileItem(
                id: item.stableID,
                name: item.name,
                unit: item.unit,
                requiredAmount: result.requiredAmount,
                currentAmount: result.currentAmount,
                shortageAmount: result.shortageAmount,
                isPrepared: item.isPrepared,
                expirationText: expirationLabel(status)
            )
        }

        return ExportStockpileSnapshot(
            adultCount: plan.adultCount,
            childCount: plan.childCount,
            seniorCount: plan.seniorCount,
            targetDays: plan.targetDays.rawValue,
            items: items
        )
    }

    private func expirationLabel(_ status: StockpileExpirationStatus) -> String? {
        switch status {
        case .none:
            nil
        case .expired(let daysAgo):
            "期限切れ（\(daysAgo)日前）"
        case .dueSoon(let daysRemaining):
            "残り\(daysRemaining)日"
        case .scheduled(let daysRemaining):
            "残り\(daysRemaining)日"
        }
    }

    private func refreshPreview() {
        guard canGenerate else {
            previewText = ""
            return
        }
        previewText = makeDocument().plainTextPreview()
    }

    private func generateAndShare() async {
        await runExport { file in
#if os(iOS)
            sharePayload = SharePayload(url: file.url)
            statusMessage = "共有シートを開きました。完了後に一時ファイルを削除します。"
#elseif os(macOS)
            NSWorkspace.shared.activateFileViewerSelecting([file.url])
            statusMessage = "PDFを生成しました。プレビューまたは印刷アプリから扱えます。一時ファイルは手動削除前に共有を終えてください。"
            // macOSではFinder表示後もファイルが必要なので、すぐには消さない。
            // 代わりに短時間後に削除するベストエフォート。
            let url = file.url
            Task {
                try? await Task.sleep(for: .seconds(120))
                cleanup(url: url)
            }
#endif
        }
    }

#if os(macOS)
    private func generateAndPrint() async {
        await runExport { file in
            let did = NSWorkspace.shared.open(file.url)
            statusMessage = did
                ? "PDFを開きました。印刷ダイアログから用紙へ出力できます。"
                : "PDFを開けませんでした。"
            let url = file.url
            Task {
                try? await Task.sleep(for: .seconds(120))
                cleanup(url: url)
            }
        }
    }
#endif

    private func runExport(onSuccess: (TemporaryExportFile) -> Void) async {
        guard canGenerate else { return }
        isWorking = true
        statusMessage = nil
        defer { isWorking = false }

        if selection.includesPersonalInformation && protection.requiresAuthenticationToReveal {
            let result = await authenticator.authenticate(
                reason: "個人情報を含むPDFを生成します"
            )
            guard result == .success else {
                statusMessage = "認証できなかったため、出力を中止しました。"
                return
            }
        }

        let document = makeDocument()
        let service = PDFExportService()
        do {
            let file = try TemporaryExportFile.makePDFURL()
            try service.writePDF(document: document, to: file)
            onSuccess(file)
        } catch PDFExportError.emptySelection {
            statusMessage = "出力する項目を選択してください。"
        } catch {
            statusMessage = "PDFを生成できませんでした。選択内容を見直してもう一度お試しください。"
            // エラー文に個人情報を載せない
        }
    }

    private func cleanup(url: URL) {
        let file = TemporaryExportFile(url: url)
        do {
            _ = try file.removeIfExists()
        } catch {
            statusMessage = "一時ファイルの削除に失敗しました。再起動後に空領域を確認してください。"
        }
    }
}

#if os(iOS)
private struct SharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
