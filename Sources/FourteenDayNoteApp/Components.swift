import FourteenDayCore
import SwiftUI

struct OfflineCapabilityBadge: View {
    var body: some View {
        Label("オフライン対応", systemImage: "wifi.slash")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(.secondary)
            .background(.quaternary, in: Capsule())
            .accessibilityLabel("オフライン対応。通信なしで利用できます")
    }
}

struct PriorityBadge: View {
    let priority: GuideArticle.Priority

    var body: some View {
        Text(priority.displayName)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
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
        case .critical: Color.red.opacity(0.85)
        case .high: Color.orange.opacity(0.35)
        case .normal: Color.secondary.opacity(0.15)
        }
    }
}

struct PeriodChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: Capsule())
    }
}

struct DraftStatusLabel: View {
    let status: GuideArticle.ReviewStatus

    var body: some View {
        Label(status.displayName, systemImage: "hammer")
            .font(.caption)
            .foregroundStyle(.orange)
    }
}
