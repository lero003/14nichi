import FourteenDayCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct OfficialLinksView: View {
    @Environment(ReadabilitySettings.self) private var readability
    @State private var catalog: OfficialLinkCatalog?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let catalog {
                    catalogList(catalog)
                } else if let loadError {
                    ContentUnavailableView {
                        Label("公式リンク集を読み込めません", systemImage: "link.badge.plus")
                    } description: {
                        Text(loadError)
                    } actions: {
                        Button("再試行", action: load)
                    }
                } else {
                    ProgressView("読み込み中…")
                }
            }
            .navigationTitle("公式情報")
        }
        .task { load() }
    }

    private func catalogList(_ catalog: OfficialLinkCatalog) -> some View {
        List {
            Section {
                Label {
                    Text(catalog.requiresOnlineNotice)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "wifi")
                }
                .accessibilityElement(children: .combine)
            } footer: {
                Text("リンクを開く操作だけが通信を使います。公的サイトの本文はアプリへ取り込みません。地域の最新指示は自治体の発表を優先してください。")
            }

            ForEach(catalog.categories) { category in
                Section(category.title) {
                    ForEach(category.links) { link in
                        Button {
                            open(link.url)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(link.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 8)
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundStyle(.secondary)
                                }
                                Text(link.purpose)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(link.url.host ?? link.url.absoluteString)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, readability.prefersGenerousSpacing ? 4 : 0)
                        }
                        .accessibilityHint("オンラインで公式サイトを開きます")
                    }
                }
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#endif
    }

    private func load() {
        do {
            catalog = try OfficialLinkCatalogLoader().loadBundledCatalog()
            loadError = nil
        } catch {
            catalog = nil
            loadError = "同梱の公式リンク集を検証できませんでした。"
        }
    }

    private func open(_ url: URL) {
        guard url.scheme?.lowercased() == "https" else { return }
#if os(iOS)
        UIApplication.shared.open(url)
#elseif os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }
}
