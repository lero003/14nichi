import FourteenDayCore
import SwiftUI

struct RootView: View {
    @State private var model = AppModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize

    var body: some View {
        Group {
            switch model.loadState {
            case .loading:
                LoadingSplashView()
                    .transition(.opacity)
            case .ready:
                ArticleBrowserView(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            case .failed(let message):
                ContentUnavailableView {
                    Label("記事を読み込めませんでした", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("再試行") {
                        withAnimation(AppTheme.spring(reduceMotion: reduceMotion)) {
                            model.load()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .transition(.opacity)
            }
        }
        .animation(AppTheme.gentle(reduceMotion: reduceMotion), value: model.loadState)
        .environment(model.readability)
        .dynamicTypeSize(model.readability.resolvedDynamicTypeSize(system: systemDynamicTypeSize))
        .task {
            if case .loading = model.loadState {
                model.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in
            model.isAboutPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showReadability)) { _ in
            model.isReadabilityPresented = true
        }
        .sheet(isPresented: $model.isAboutPresented) {
            AboutView()
#if os(macOS)
                .frame(minWidth: 440, minHeight: 520)
#endif
        }
        .sheet(isPresented: $model.isReadabilityPresented) {
            ReadabilityView(settings: model.readability)
#if os(macOS)
                .frame(minWidth: 460, minHeight: 560)
#endif
        }
    }
}

#Preview {
    RootView()
}
