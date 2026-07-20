import SwiftUI

struct ReadabilityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    @Bindable var settings: ReadabilitySettings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    textSizeSection
                    optionsSection
                    previewSection
                }
                .padding()
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("読みやすさ")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("文字の大きさや余白を、このアプリだけで調整できます。")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("初期値は標準です。小さめから大きな文字まで選べ、設定はこの端末に保存されます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var textSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文字サイズ")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 10) {
                ForEach(ReadabilitySettings.TextSize.allCases) { size in
                    Button {
                        withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                            settings.textSize = size
                        }
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(size.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(size.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if settings.textSize == size {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                                    .imageScale(.large)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.tertiary)
                                    .imageScale(.large)
                            }
                        }
                        .padding(14)
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(settings.textSize == size ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    settings.textSize == size ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PressableScaleButtonStyle())
                    .accessibilityLabel("文字サイズ \(size.title)")
                    .accessibilityAddTraits(settings.textSize == size ? [.isSelected] : [])
                }
            }

        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("表示の調整")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            SurfaceCard {
                Toggle(isOn: $settings.prefersBoldBody) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("文字を少し太くする")
                        Text("細い線が読みにくいときに使います")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 4)

                Divider().padding(.vertical, 4)

                Toggle(isOn: $settings.prefersGenerousSpacing) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("余白と行間を広げる")
                        Text("詰まった画面を避け、指で押しやすくします")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.vertical, 4)
            }
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレビュー")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            SurfaceCard {
                VStack(alignment: .leading, spacing: settings.resolvedLineSpacing) {
                    Text("停電した直後にすること")
                        .font(.title2.weight(.bold))
                    Text("文字サイズを変えると、この見出しと本文の見え方が変わります。長い文章が無理なく折り返されることも確認できます。")
                        .font(settings.prefersBoldBody ? .body.weight(.medium) : .body)
                        .lineSpacing(settings.resolvedLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                    OfflineCapabilityBadge()
                }
            }
            .environment(
                \.dynamicTypeSize,
                settings.resolvedDynamicTypeSize(system: systemDynamicTypeSize)
            )
        }
    }
}

#Preview {
    ReadabilityView(settings: ReadabilitySettings())
}
