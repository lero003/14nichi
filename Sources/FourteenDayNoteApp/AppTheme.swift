import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 20
    static let chipRadius: CGFloat = 10
    static let iconWellSize: CGFloat = 44
    static let contentGutter: CGFloat = 20

    /// アプリアイコンと共通のブランド色。警報色の全面使用は避ける。
    static let accent = Color("AccentColor", bundle: nil)
    static let deepTeal = Color(red: 0.02, green: 0.29, blue: 0.31)
    static let teal = Color(red: 0.04, green: 0.39, blue: 0.41)
    static let ivory = Color(red: 1.00, green: 0.96, blue: 0.86)
    static let ochre = Color(red: 0.88, green: 0.62, blue: 0.16)
    static let coral = Color(red: 0.92, green: 0.31, blue: 0.25)

    static let canvas = accent.opacity(0.035)
    static let surfaceStroke = accent.opacity(0.13)
    static let elevatedShadow = Color.black.opacity(0.08)

    static let brandGradient = LinearGradient(
        colors: [deepTeal, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.surfaceStroke, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? .clear : AppTheme.elevatedShadow,
                radius: 12,
                y: 5
            )
    }

    private var cardFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.055)
            : AppTheme.ivory.opacity(0.72)
    }
}

struct IconWell: View {
    let systemName: String
    var tint: Color = AppTheme.accent

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: AppTheme.iconWellSize, height: AppTheme.iconWellSize)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.13))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint.opacity(0.12), lineWidth: 1)
            }
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
