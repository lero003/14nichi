import FourteenDayCore
import SwiftData
import SwiftUI

struct EmergencyCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ReadabilitySettings.self) private var readability
    @Query private var cards: [EmergencyCardSchemaV1.Card]

    @State private var draft = EmergencyCardSnapshot()
    @State private var isEditing = false
    @State private var isUnlocked = false
    @State private var persistenceError: String?
    @State private var authMessage: String?
    @State private var protection = EmergencyCardProtectionStore().load()
    @State private var showDeleteConfirmation = false
    @State private var authenticator = LocalAuthenticationService()
    private let protectionStore = EmergencyCardProtectionStore()

    var body: some View {
        NavigationStack {
            Group {
                if primaryCard == nil && persistenceError != nil {
                    ContentUnavailableView {
                        Label("緊急カードを開けません", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(persistenceError ?? "")
                    } actions: {
                        Button("もう一度試す", action: loadCard)
                    }
                } else if needsUnlock {
                    lockedState
                } else {
                    content
                }
            }
            .navigationTitle("緊急カード")
            .toolbar { toolbar }
            .privacyShield(enabled: true)
        }
        .task {
            loadCard()
            await revealIfAllowed(automatic: true)
        }
        .onChange(of: protection.requiresAuthenticationToReveal) { _, requires in
            protectionStore.save(protection)
            if requires {
                isUnlocked = false
            } else {
                isUnlocked = true
                authMessage = nil
            }
        }
        .confirmationDialog(
            "緊急カードをすべて削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("すべて削除", role: .destructive, action: deleteAll)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("連絡先・集合場所・アレルギーなどの端末内データが削除されます。備蓄やお気に入りは消えません。この操作は取り消せません。")
        }
    }

    private var primaryCard: EmergencyCardSchemaV1.Card? {
        cards.first { $0.stableID == EmergencyCardStore.primaryCardID }
    }

    private var needsUnlock: Bool {
        protection.requiresAuthenticationToReveal && isUnlocked == false
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if needsUnlock == false {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "完了" : "編集") {
                    if isEditing {
                        saveDraft()
                    } else {
                        isEditing = true
                    }
                }
            }
        }
    }

    private var lockedState: some View {
        ContentUnavailableView {
            Label("認証が必要です", systemImage: "lock.fill")
        } description: {
            Text(authMessage ?? "緊急カードの表示には、この端末のロック解除（Face ID / Touch ID / パスコード）が必要です。")
        } actions: {
            Button("認証して表示") {
                Task { await revealIfAllowed(automatic: false) }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: readability.sectionSpacing) {
                introduction
                protectionSection

                if isEditing {
                    editorSections
                } else {
                    readOnlySections
                }

                if draft.hasAnyContent || isEditing {
                    dangerZone
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

    private var introduction: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("30秒で確認する最小情報", systemImage: "person.text.rectangle")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)

                Text("連絡先・集合場所・アレルギーなど、緊急時にすぐ必要な項目だけを端末内へ保存します。健康保険番号や生年月日は扱いません。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("診断や処方の代替ではありません。救急時は119と現場の指示を優先してください。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var protectionSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("表示の保護")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Toggle(
                    "表示前に端末認証を求める",
                    isOn: $protection.requiresAuthenticationToReveal
                )
                .disabled(protection.requiresAuthenticationToReveal == false && authenticator.canEvaluate() == false)

                Text(
                    protection.requiresAuthenticationToReveal
                        ? "アプリを開いたあと、カード本文の表示に認証が必要です。既定ではオフです（端末自体のロックを主防御とします）。"
                        : "既定はオフです。紛失時の主防御は端末のパスコードとデータ消去設定です。避難所などでのぞき見が気になる場合のみオンにしてください。"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if authenticator.canEvaluate() == false {
                    Text("この端末では生体認証/パスコードによる追加ロックを利用できません。")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private var readOnlySections: some View {
        if draft.isEmpty {
            ContentUnavailableView {
                Label("まだ登録がありません", systemImage: "square.and.pencil")
            } description: {
                Text("右上の編集から、連絡先や集合場所を追加できます。未入力のままでも他の機能は使えます。")
            }
        } else {
            if draft.displayName.isEmpty == false {
                infoCard(title: "表示名", systemImage: "person", value: draft.displayName)
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("緊急連絡先", systemImage: "phone")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    if draft.contacts.isEmpty {
                        Text("未登録")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(draft.contacts) { contact in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name.isEmpty ? "（名前未設定）" : contact.name)
                                    .font(.body.weight(.semibold))
                                if contact.relation.isEmpty == false {
                                    Text(contact.relation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if contact.phone.isEmpty == false {
                                    Text(contact.phone)
                                        .font(.title3.monospacedDigit())
                                        .accessibilityLabel("電話番号 \(contact.phone)")
                                }
                            }
                            .padding(.vertical, 4)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }

            if draft.meetingPlace.isEmpty == false {
                infoCard(title: "集合場所", systemImage: "figure.2.and.child.holdinghands", value: draft.meetingPlace)
            }
            if draft.evacuationPlace.isEmpty == false {
                infoCard(title: "避難予定場所", systemImage: "house.lodge", value: draft.evacuationPlace)
            }
            if draft.allergies.isEmpty == false {
                infoCard(title: "アレルギー", systemImage: "allergens", value: draft.allergies)
            }
            if draft.medications.isEmpty == false {
                infoCard(title: "常用薬", systemImage: "pills", value: draft.medications)
            }
            if draft.notes.isEmpty == false {
                infoCard(title: "注意メモ", systemImage: "note.text", value: draft.notes)
            }
        }
    }

    private var editorSections: some View {
        Group {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("基本")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    TextField("表示名（任意）", text: $draft.displayName)
                    TextField("集合場所（任意）", text: $draft.meetingPlace, axis: .vertical)
                    TextField("避難予定場所（任意）", text: $draft.evacuationPlace, axis: .vertical)
                }
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("緊急連絡先")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button("追加") {
                            addContact()
                        }
                        .disabled(draft.contacts.count >= EmergencyCardLimits.maxContacts)
                    }

                    if draft.contacts.isEmpty {
                        Text("最大\(EmergencyCardLimits.maxContacts)件。氏名と電話番号を入力できます。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach($draft.contacts) { $contact in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("名前", text: $contact.name)
                            TextField("電話番号", text: $contact.phone)
#if os(iOS)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
#endif
                            TextField("続柄・関係（任意）", text: $contact.relation)
                            Button("この連絡先を削除", role: .destructive) {
                                draft.contacts.removeAll { $0.id == contact.id }
                            }
                            .font(.footnote)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("健康関連（任意・最小）")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    TextField("アレルギー", text: $draft.allergies, axis: .vertical)
                    TextField("常用薬（名称レベル）", text: $draft.medications, axis: .vertical)
                    Text("用量・保険証番号・マイナンバーは書かないでください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("注意メモ（任意）")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    TextField("ブレーカーや元栓など短いメモ", text: $draft.notes, axis: .vertical)
                    Text("暗証番号やクレジットカード番号は書かないでください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var dangerZone: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("削除")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("緊急カードの内容だけを端末から削除します。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("緊急カードをすべて削除", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
    }

    private func infoCard(title: String, systemImage: String, value: String) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(value)
                    .font(readability.prefersBoldBody ? .body.weight(.medium) : .body)
                    .lineSpacing(readability.resolvedLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func loadCard() {
        do {
            let card = try EmergencyCardStore.loadOrCreateCard(in: modelContext)
            draft = card.snapshot
            persistenceError = nil
            if protection.requiresAuthenticationToReveal == false {
                isUnlocked = true
            }
        } catch {
            persistenceError = "端末内の緊急カードを準備できませんでした。"
        }
    }

    private func saveDraft() {
        do {
            let card = try EmergencyCardStore.updateCard(draft, in: modelContext)
            draft = card.snapshot
            isEditing = false
            persistenceError = nil
        } catch {
            persistenceError = "変更を保存できませんでした。もう一度お試しください。"
        }
    }

    private func addContact() {
        guard draft.contacts.count < EmergencyCardLimits.maxContacts else { return }
        draft.contacts.append(
            EmergencyContactSnapshot(sortOrder: draft.contacts.count)
        )
    }

    private func deleteAll() {
        do {
            try EmergencyCardStore.deleteAll(in: modelContext)
            _ = try EmergencyCardStore.loadOrCreateCard(in: modelContext)
            draft = EmergencyCardSnapshot()
            isEditing = false
            persistenceError = nil
        } catch {
            persistenceError = "削除できませんでした。もう一度お試しください。"
        }
    }

    private func revealIfAllowed(automatic: Bool) async {
        guard protection.requiresAuthenticationToReveal else {
            isUnlocked = true
            return
        }
        if automatic && isUnlocked {
            return
        }

        let result = await authenticator.authenticate(
            reason: "緊急カードに含まれる個人情報を表示します"
        )
        switch result {
        case .success:
            isUnlocked = true
            authMessage = nil
        case .cancelled:
            isUnlocked = false
            authMessage = "認証がキャンセルされました。"
        case .failed:
            isUnlocked = false
            authMessage = "認証に失敗しました。もう一度お試しください。"
        case .notAvailable:
            isUnlocked = false
            authMessage = "この端末では追加の認証を利用できません。設定をオフにするか、端末のパスコードを確認してください。"
        }
    }
}
