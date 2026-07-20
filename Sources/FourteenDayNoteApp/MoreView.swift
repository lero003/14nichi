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
            }
            .navigationTitle("その他")
        }
    }
}
