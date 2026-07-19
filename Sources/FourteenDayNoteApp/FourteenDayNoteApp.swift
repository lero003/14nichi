import SwiftUI

@main
struct FourteenDayNoteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
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
}

extension Notification.Name {
    static let showAbout = Notification.Name("jp.hazakura.FourteenDayNote.showAbout")
    static let showReadability = Notification.Name("jp.hazakura.FourteenDayNote.showReadability")
}
