import FourteenDayCore
import SwiftData
import SwiftUI

@main
struct FourteenDayNoteApp: App {
    private let containers = AppContainers.live()

    var body: some Scene {
        WindowGroup {
            rootContent
        }
#if os(macOS)
        .defaultSize(width: 1160, height: 760)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("14日ノートについて…") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
            CommandGroup(after: .textEditing) {
                Button("読みやすさ…") {
                    NotificationCenter.default.post(name: .showReadability, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button("14日ノートについて") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
                .keyboardShortcut("?", modifiers: [.command])
                Button("読みやすさ") {
                    NotificationCenter.default.post(name: .showReadability, object: nil)
                }
            }
        }
#endif
    }

    @ViewBuilder
    private var rootContent: some View {
        switch containers.stockpile {
        case .success(let stockpileContainer):
            RootView(emergencyContainer: emergencyContainerOrNil)
                .modelContainer(stockpileContainer)
        case .failure(let error):
            ContentUnavailableView {
                Label("保存領域を開けません", systemImage: "externaldrive.badge.exclamationmark")
            } description: {
                Text("備蓄データの保存領域を準備できませんでした。アプリを終了して、もう一度開いてください。\n\(error.localizedDescription)")
            }
        }
    }

    private var emergencyContainerOrNil: ModelContainer? {
        if case .success(let container) = containers.emergencyCard {
            return container
        }
        return nil
    }
}

extension Notification.Name {
    static let showAbout = Notification.Name("jp.hazakura.FourteenDayNote.showAbout")
    static let showReadability = Notification.Name("jp.hazakura.FourteenDayNote.showReadability")
}
