import FourteenDayCore
import SwiftData
import SwiftUI

/// 公式リンクとPDF出力をまとめる補助タブ。30秒到達の主導線（ガイド）は妨げない。
struct MoreView: View {
    let emergencyContainer: ModelContainer?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        OfficialLinksView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("公式情報リンク集")
                                Text("公的機関のサイトへ（オンライン）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "link.circle")
                        }
                    }

                    NavigationLink {
                        ExportView(emergencyContainer: emergencyContainer)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PDF・印刷")
                                Text("項目を選んで紙やファイルへ")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "printer")
                        }
                    }
                } header: {
                    Text("準備と出力")
                } footer: {
                    Text("ガイド本文はオフラインのままです。公式サイトを開く操作と、PDFの共有・印刷だけが端末の外へ情報を出します。")
                }

                Section {
                    externalLink(
                        title: "サポート",
                        subtitle: "お問い合わせ・よくある質問",
                        systemImage: "questionmark.circle",
                        destination: AppExternalLinks.support
                    )

                    externalLink(
                        title: "プライバシーポリシー",
                        subtitle: "端末内データの取り扱い",
                        systemImage: "hand.raised",
                        destination: AppExternalLinks.privacyPolicy
                    )
                } header: {
                    Text("サポートとプライバシー")
                } footer: {
                    Text("公式サイトを開くため、オンライン接続が必要です。")
                }
            }
            .navigationTitle("その他")
        }
    }

    private func externalLink(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: URL
    ) -> some View {
        Link(destination: destination) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
        }
        .accessibilityHint("通信を使用して外部サイトを開きます")
    }
}
