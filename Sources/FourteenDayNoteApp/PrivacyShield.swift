import SwiftUI

/// 非アクティブ時に個人情報画面を覆う。App Switcher への平文露出を抑える。
struct PrivacyShieldModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    var enabled: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isShielding ? 0 : 1)
                .accessibilityHidden(isShielding)

            if isShielding {
                ZStack {
                    Rectangle()
                        .fill(.background)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "eye.slash.fill")
                            .font(.largeTitle)
                        Text("個人情報を非表示にしています")
                            .font(.headline)
                        Text("アプリに戻ってから、必要に応じて認証してください。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("個人情報を非表示にしています")
            }
        }
    }

    private var isShielding: Bool {
        enabled && scenePhase != .active
    }
}

extension View {
    func privacyShield(enabled: Bool) -> some View {
        modifier(PrivacyShieldModifier(enabled: enabled))
    }
}
