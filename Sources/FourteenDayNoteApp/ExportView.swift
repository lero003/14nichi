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
    @Environment(\.scenePhase) private var scenePhase

    let emergencyContainer: ModelContainer?

    @Query private var plans: [StockpileSchema.Plan]
    @State private var selection = ExportSelection.privacySafeDefault
    @State private var emergencyCard = EmergencyCardSnapshot()
    @State private var acknowledgedPersonalData = false
    @State private var previewText = ""
    @State private var statusMessage: String?
    @State private var isWorking = false
    @State private var authenticator = LocalAuthenticationService()
    @State private var protection = EmergencyCardProtectionStore().load()
    @State private var emergencyContentUnlocked = false
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
                    if emergencyContainer == nil {
                        Text("緊急カードの保存領域を開けていないため、個人情報は出力できません。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Toggle("表示名", isOn: $selection.includeDisplayName)
                        .disabled(emergencyContainer == nil)
                    Toggle("緊急連絡先", isOn: $selection.includeContacts)
                        .disabled(emergencyContainer == nil)
                    Toggle("集合場所", isOn: $selection.includeMeetingPlace)
                        .disabled(emergencyContainer == nil)
                    Toggle("避難予定場所", isOn: $selection.includeEvacuationPlace)
                        .disabled(emergencyContainer == nil)
                    Toggle("アレルギー", isOn: $selection.includeAllergies)
                        .disabled(emergencyContainer == nil)
                    Toggle("常用薬", isOn: $selection.includeMedications)
                        .disabled(emergencyContainer == nil)
                    Toggle("注意メモ", isOn: $selection.includeNotes)
                        .disabled(emergencyContainer == nil)
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
                    } else if requiresEmergencyAuthentication {
                        Text("個人情報のプレビューは、PDF生成時の端末認証後に表示します。")
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
            .onChange(of: scenePhase) { _, phase in
                guard phase != .active, protection.requiresAuthenticationToReveal else { return }
                emergencyContentUnlocked = false
                refreshPreview()
            }
            .task {
                cleanupStaleExports()
                loadSources()
                refreshPreview()
            }
            .onAppear {
                // スタックから戻って再表示したときに、編集済みの緊急カードを取り直す
                loadSources()
                refreshPreview()
            }
#if os(iOS)
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: [payload.file.url])
                    .onDisappear {
                        cleanup(file: payload.file)
                    }
            }
#endif
        }
        .privacyShield(enabled: selection.includesPersonalInformation)
    }

    private var canGenerate: Bool {
        guard selection.hasAnySelection else { return false }
        if selection.includesPersonalInformation {
            // ストアが開けない状態で空の個人情報PDFを出さない
            guard emergencyContainer != nil else { return false }
            return acknowledgedPersonalData
        }
        return true
    }

    private var requiresEmergencyAuthentication: Bool {
        selection.includesPersonalInformation
            && protection.requiresAuthenticationToReveal
            && emergencyContentUnlocked == false
    }

    private var primaryPlan: StockpileSchema.Plan? {
        plans.first { $0.stableID == StockpileStore.primaryPlanID }
    }

    private func loadSources() {
        if let emergencyContainer {
            let context = ModelContext(emergencyContainer)
            do {
                let card = try EmergencyCardStore.loadOrCreateCard(in: context)
                emergencyCard = card.snapshot
            } catch {
                emergencyCard = EmergencyCardSnapshot()
                clearPersonalSelection()
                statusMessage = "緊急カードを読み込めないため、個人情報の出力をオフにしました。"
            }
        } else {
            emergencyCard = EmergencyCardSnapshot()
            // 個人情報トグルが残っていても出力できないよう落とす
            clearPersonalSelection()
        }
        if primaryPlan == nil {
            do {
                _ = try StockpileStore.loadOrCreatePlan(in: stockpileContext)
            } catch {
                statusMessage = statusMessage
                    ?? "備蓄データを読み込めませんでした。備蓄画面で保存状態を確認してください。"
            }
        }
        protection = EmergencyCardProtectionStore().load()
        emergencyContentUnlocked = protection.requiresAuthenticationToReveal == false
    }

    private func clearPersonalSelection() {
        selection.includeDisplayName = false
        selection.includeContacts = false
        selection.includeMeetingPlace = false
        selection.includeEvacuationPlace = false
        selection.includeAllergies = false
        selection.includeMedications = false
        selection.includeNotes = false
        acknowledgedPersonalData = false
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
        .filter(\.isShortage)
        .map { item in
            let recommendation = StockpileRecommendations.recommendation(id: item.stableID)
            let isChecklist = recommendation?.isQuantified == false
            if isChecklist {
                return ExportStockpileItem(
                    id: item.stableID,
                    name: item.name,
                    unit: item.unit,
                    requiredAmount: 0,
                    currentAmount: 0,
                    shortageAmount: 0,
                    isPrepared: item.isPurchased,
                    expirationText: nil,
                    isChecklistOnly: true
                )
            }
            let result = StockpileCalculator.calculate(
                entry: item.calculationEntry,
                household: household,
                targetDays: plan.targetDays
            )
            return ExportStockpileItem(
                id: item.stableID,
                name: item.name,
                unit: item.unit,
                requiredAmount: result.requiredAmount,
                currentAmount: item.isPurchased ? result.requiredAmount : 0,
                shortageAmount: item.isPurchased ? 0 : result.requiredAmount,
                isPrepared: item.isPurchased,
                expirationText: nil,
                isChecklistOnly: false
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

    private func refreshPreview() {
        guard canGenerate, requiresEmergencyAuthentication == false else {
            previewText = ""
            return
        }
        previewText = makeDocument().plainTextPreview()
    }

    private func generateAndShare() async {
        await runExport { file in
#if os(iOS)
            sharePayload = SharePayload(file: file)
            statusMessage = "共有シートを開きました。完了後に一時ファイルを削除します。"
#elseif os(macOS)
            NSWorkspace.shared.activateFileViewerSelecting([file.url])
            statusMessage = "PDFを生成しました。プレビューまたは印刷アプリから扱えます。一時ファイルは手動削除前に共有を終えてください。"
            // macOSではFinder表示後もファイルが必要なので、すぐには消さない。
            // 代わりに短時間後に削除するベストエフォート。
            Task {
                try? await Task.sleep(for: .seconds(120))
                cleanup(file: file)
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
            Task {
                try? await Task.sleep(for: .seconds(120))
                cleanup(file: file)
            }
        }
    }
#endif

    private func runExport(onSuccess: (TemporaryExportFile) -> Void) async {
        guard canGenerate else { return }
        isWorking = true
        statusMessage = nil
        defer { isWorking = false }

        if requiresEmergencyAuthentication {
            let result = await authenticator.authenticate(
                reason: "個人情報を含むPDFを生成します"
            )
            guard result == .success else {
                statusMessage = "認証できなかったため、出力を中止しました。"
                return
            }
            emergencyContentUnlocked = true
            refreshPreview()
        }

        let document = makeDocument()
        let service = PDFExportService()
        var temporaryFile: TemporaryExportFile?
        do {
            let file = try TemporaryExportFile.makePDFURL()
            temporaryFile = file
            try service.writePDF(document: document, to: file)
            onSuccess(file)
        } catch {
            let cleanupFailed: Bool
            if let temporaryFile {
                do {
                    _ = try temporaryFile.removeIfExists()
                    cleanupFailed = false
                } catch {
                    cleanupFailed = true
                }
            } else {
                cleanupFailed = false
            }

            if let exportError = error as? PDFExportError, exportError == .emptySelection {
                statusMessage = "出力する項目を選択してください。"
            } else if cleanupFailed {
                statusMessage = "PDFを生成できず、一時ファイルも削除できませんでした。アプリを再起動してからもう一度お試しください。"
            } else {
                statusMessage = "PDFを生成できませんでした。選択内容を見直してもう一度お試しください。"
            }
            // エラー文に個人情報を載せない
        }
    }

    private func cleanupStaleExports() {
        do {
            _ = try TemporaryExportFile.removeAllTemporaryExports()
        } catch {
            statusMessage = "前回のPDF一時ファイルを削除できませんでした。空き容量を確認してアプリを再起動してください。"
        }
    }

    private func cleanup(file: TemporaryExportFile) {
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
    let file: TemporaryExportFile
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
