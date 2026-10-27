#if DEBUG
import SwiftUI

/// UIテスト専用。スクロール中の本文全体の高さ補正を、画面を再描画せず記録する。
struct ArticleScrollDiagnostics: ViewModifier {
    let readingPosition: String?
    @State private var probe = ArticleScrollProbe()
    @State private var summary = "gestures=0;heightChanges=0;maxCorrection=0"

    func body(content: Content) -> some View {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-scroll-probe") {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentSize.height
                } action: { oldHeight, newHeight in
                    probe.recordHeightChange(from: oldHeight, to: newHeight)
                }
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting {
                        probe.isScrolling = true
                    } else if phase == .idle, probe.isScrolling {
                        probe.isScrolling = false
                        probe.gestures += 1
                        summary = probe.summary
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text("anchor=\(readingPosition ?? "nil");\(summary)")
                        .font(.caption2.monospacedDigit())
                        .padding(4)
                        .background(.regularMaterial)
                        .allowsHitTesting(false)
                        .accessibilityIdentifier("testing.articleScrollMetrics")
                }
        } else {
            content
        }
    }
}

/// 非Observableの参照型。geometryの各イベントをSwiftUIのStateへ流し戻さない。
private final class ArticleScrollProbe {
    var isScrolling = false
    var gestures = 0
    private var heightChanges = 0
    private var maxCorrection: CGFloat = 0

    func recordHeightChange(from oldHeight: CGFloat, to newHeight: CGFloat) {
        guard isScrolling else { return }
        let correction = abs(newHeight - oldHeight)
        guard correction > 1 else { return }
        heightChanges += 1
        maxCorrection = max(maxCorrection, correction)
    }

    var summary: String {
        "gestures=\(gestures);heightChanges=\(heightChanges);maxCorrection=\(Int(maxCorrection.rounded()))"
    }
}
#endif
