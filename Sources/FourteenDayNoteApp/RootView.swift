import FourteenDayCore
import SwiftUI

struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        Group {
            switch model.loadState {
            case .loading:
                ProgressView("記事を読み込んでいます…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready:
                ArticleBrowserView(model: model)
            case .failed(let message):
                ContentUnavailableView {
                    Label("記事を読み込めませんでした", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("再試行") {
                        model.load()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            if case .loading = model.loadState {
                model.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in
            model.isAboutPresented = true
        }
        .sheet(isPresented: $model.isAboutPresented) {
            AboutView()
#if os(macOS)
                .frame(minWidth: 420, minHeight: 480)
#endif
        }
    }
}

#Preview {
    RootView()
}
