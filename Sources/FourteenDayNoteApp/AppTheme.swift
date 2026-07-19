import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 18
    static let chipRadius: CGFloat = 10
    static let iconWellSize: CGFloat = 44
    static let contentGutter: CGFloat = 20

    /// 落ち着いた深みのアクセント。警報色の全面使用は避ける。
    static let accent = Color("AccentColor", bundle: nil)

    static let surfaceFill = Color.primary.opacity(0.04)
    static let surfaceStroke = Color.primary.opacity(0.08)
    static let elevatedShadow = Color.black.opacity(0.08)

    static func spring(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86)
    }

    static func snappy(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: 0.28, extraBounce: 0.05)
    }

    static func gentle(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.22)
    }
}

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(.background.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
            )
    }
}

struct IconWell: View {
    let systemName: String
    var tint: Color = .accentColor

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: AppTheme.iconWellSize, height: AppTheme.iconWellSize)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .accessibilityHidden(true)
    }
}

struct PressableScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AppTheme.snappy(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
