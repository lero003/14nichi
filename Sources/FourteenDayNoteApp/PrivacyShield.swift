import SwiftUI

/// 非アクティブ時に個人情報画面を覆う。App Switcher への平文露出を抑える。
struct PrivacyShieldModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    var enabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if enabled && scenePhase != .active {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        VStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .font(.largeTitle)
                            Text("個人情報を非表示にしています")
                                .font(.headline)
                            Text("アプリに戻ると表示を再開します。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("個人情報を非表示にしています")
                }
            }
            // キャプチャされにくいよう、非アクティブ時はコンテンツを隠す
            .opacity(enabled && scenePhase != .active ? 0.02 : 1)
    }
}

extension View {
    func privacyShield(enabled: Bool) -> some View {
        modifier(PrivacyShieldModifier(enabled: enabled))
    }
}
