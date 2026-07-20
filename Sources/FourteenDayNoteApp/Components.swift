import FourteenDayCore
import SwiftUI

struct OfflineCapabilityBadge: View {
    var body: some View {
        Label("オフライン対応", systemImage: "wifi.slash")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(.secondary)
            .background(.quaternary, in: Capsule())
            .accessibilityLabel("オフライン対応。通信なしで利用できます")
    }
}

struct PriorityBadge: View {
    let priority: GuideArticle.Priority

    var body: some View {
        Text(priority.displayName)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
            .accessibilityLabel("優先度 \(priority.displayName)")
    }

    private var foreground: Color {
        switch priority {
        case .critical: .white
        case .high: .primary
        case .normal: .secondary
        }
    }

    private var background: Color {
        switch priority {
        case .critical: Color.red.opacity(0.82)
        case .high: Color.orange.opacity(0.32)
        case .normal: Color.secondary.opacity(0.14)
        }
    }
}

struct PeriodChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }
}

struct DraftStatusLabel: View {
    let status: GuideArticle.ReviewStatus

    var body: some View {
        Label(status.displayName, systemImage: "hammer.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
    }
}

struct FavoriteStatusLabel: View {
    var body: some View {
        Label("お気に入り", systemImage: "heart.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tint)
    }
}

struct LoadingSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulse && !reduceMotion ? 1.08 : 1)
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }
            VStack(spacing: 6) {
                Text("14日ノート")
                    .font(.title2.weight(.bold))
                Text("記事を読み込んでいます…")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
