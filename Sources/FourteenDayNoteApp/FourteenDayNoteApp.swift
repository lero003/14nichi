import SwiftUI

@main
struct FourteenDayNoteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
#if os(macOS)
        .defaultSize(width: 1120, height: 740)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("14日ノートについて…") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
            CommandGroup(replacing: .help) {
                Button("14日ノートについて") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
#endif
    }
}

extension Notification.Name {
    static let showAbout = Notification.Name("jp.hazakura.FourteenDayNote.showAbout")
}
