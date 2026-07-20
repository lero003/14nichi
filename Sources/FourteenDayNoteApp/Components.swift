import FourteenDayCore
import SwiftUI

struct OfflineCapabilityBadge: View {
    var body: some View {
        Label("オフライン対応", systemImage: "wifi.slash")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(AppTheme.deepTeal)
            .background(AppTheme.ivory.opacity(0.92), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppTheme.deepTeal.opacity(0.12), lineWidth: 1)
            }
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
        case .critical: AppTheme.coral
        case .high: AppTheme.ochre.opacity(0.38)
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
            .foregroundStyle(AppTheme.accent)
            .background(AppTheme.accent.opacity(0.10), in: Capsule())
    }
}

struct DraftStatusLabel: View {
    let status: GuideArticle.ReviewStatus

    var body: some View {
        Label(status.displayName, systemImage: "hammer.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.ochre)
    }
}

struct FavoriteStatusLabel: View {
    var body: some View {
        Label("お気に入り", systemImage: "heart.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.coral)
    }
}

struct LoadingSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            BrandMark(size: 96)
                .scaleEffect(pulse && !reduceMotion ? 1.04 : 1)
            VStack(spacing: 6) {
                Text("14日ノート")
                    .font(.title2.weight(.bold))
                Text("記事を読み込んでいます…")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// アイコンの「家・ノート・完了」を小さな画面内でも読める形へ簡略化したブランドマーク。
struct BrandMark: View {
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(AppTheme.ivory)

            Image(systemName: "house.fill")
                .font(.system(size: size * 0.39, weight: .bold))
                .foregroundStyle(AppTheme.deepTeal)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: size * 0.28, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(AppTheme.ivory, AppTheme.coral)
                .offset(x: size * 0.29, y: size * 0.29)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.16), radius: size * 0.08, y: size * 0.04)
        .accessibilityHidden(true)
    }
}

struct GuideHeroCard: View {
    let situationCount: Int
    let articleCount: Int
    var showsMark = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("14日ノート")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.ochre)

                Text("備えを、今日から\n少しずつ。")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.ivory)
                    .fixedSize(horizontal: false, vertical: true)

                Text("いまの状況から、次に読む記事を選べます。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.ivory.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        heroMetrics
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        heroMetrics
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsMark && !dynamicTypeSize.isAccessibilitySize {
                BrandMark(size: 78)
            }
        }
        .padding(showsMark ? 20 : 16)
        .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.ochre.opacity(0.16))
                .frame(width: 110, height: 110)
                .offset(x: 44, y: -48)
                .accessibilityHidden(true)
        }
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: AppTheme.deepTeal.opacity(0.18), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("14日ノート。備えを今日から少しずつ。状況 \(situationCount)件、記事 \(articleCount)件")
    }

    private func heroMetric(systemName: String, text: String) -> some View {
        Label(text, systemImage: systemName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.ivory)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.10), in: Capsule())
    }

    @ViewBuilder
    private var heroMetrics: some View {
        heroMetric(systemName: "checklist", text: "状況 \(situationCount)件")
        heroMetric(systemName: "doc.text", text: "記事 \(articleCount)件")
    }
}
