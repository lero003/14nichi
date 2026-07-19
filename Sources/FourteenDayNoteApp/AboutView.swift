import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadabilitySettings.self) private var readability

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: readability.sectionSpacing) {
                    header
                    section(
                        title: "このアプリについて",
                        body: "災害や生活インフラの一時的な停止に備えて、状況別に次の行動をオフラインで確認するためのノートです。ログインや常時通信は不要です。"
                    )
                    section(
                        title: "読みやすさ",
                        body: "右上の「読みやすさ」から、文字サイズ・行間・太さを変更できます。年齢や視力に合わせて、端末の設定とは別に大きくできます。"
                    )
                    section(
                        title: "いまの段階",
                        body: "現在はオフライン閲覧基盤の開発版です。同梱記事の多くは制作確認用で、正式な防災・医療・食品衛生の案内として使う前に監修が必要です。"
                    )
                    section(
                        title: "情報源の扱い",
                        body: "本文は自前で整理し、公的な一次情報への参照を記録します。長い原文の転載は行いません。各記事の「情報源」に発行者・確認日・利用形態を表示します。"
                    )
                    section(
                        title: "優先すること",
                        body: "緊急時は、このアプリより消防・救急・自治体・現場の指示を優先してください。"
                    )
                }
                .padding(AppTheme.contentGutter)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("14日ノートについて")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("14日ノート")
                .font(.largeTitle.weight(.bold))
                .tracking(-0.4)
            Text("数週間の生活混乱を乗り切るためのオフライン生活ガイド")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(readability.resolvedLineSpacing * 0.5)
                .fixedSize(horizontal: false, vertical: true)
            OfflineCapabilityBadge()
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }

    private func section(title: String, body: String) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(body)
                    .font(readability.prefersBoldBody ? .body.weight(.medium) : .body)
                    .lineSpacing(readability.resolvedLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    AboutView()
        .environment(ReadabilitySettings())
}
