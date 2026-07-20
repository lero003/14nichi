import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadabilitySettings.self) private var readability

    private static let productURL = URL(string: "https://hazakura.dev/14nichi-note/")!
    private static let supportURL = URL(string: "https://hazakura.dev/14nichi-note/support/")!
    private static let privacyURL = URL(string: "https://hazakura.dev/14nichi-note/privacy/")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: readability.sectionSpacing) {
                    header
                    section(
                        title: "14日ノートとは",
                        body: "巨大な防災百科事典ではなく、災害や停電、断水、通信・物流の停止で日常が一時的に止まったとき、個人や家庭が約2週間を落ち着いて生活するためのオフライン行動帳です。ログイン不要。広告なし。基本機能は通信なしで使えます。"
                    )
                    section(
                        title: "平時と緊急時に使う",
                        body: "平時は7日・14日の備蓄と緊急カードを整え、必要なものを自分のノートとして確認します。緊急時は状況別の記事から、その時点の次の一手を探せます。"
                    )
                    section(
                        title: "できること",
                        body: "状況別の行動ガイド、全文検索と絞り込み、水・食料・携帯トイレの一般的な目安、緊急カード（端末内のみ）、公式リンク集、PDF・印刷を備えています。"
                    )
                    section(
                        title: "読みやすさ",
                        body: "右上の「読みやすさ」から、文字サイズ・行間・太さを変更できます。年齢や視力に合わせて、端末の設定を保ちながら読みやすさを調整できます。"
                    )
                    section(
                        title: "記事の確認状態",
                        body: "同梱記事は、公的一次情報との照合と編集確認を行った正式版です。ただし、専門資格者による個別の診断や現場判断の代わりではなく、状況や情報更新によって不正確または古くなる可能性があります。最新の公式情報と現場の指示を優先してください。緊急カードの個人情報は端末内のみに保存し、外部へ送信しません。"
                    )
                    section(
                        title: "情報源の扱い",
                        body: "本文は自前で整理し、公的な一次情報への参照を記録します。長い原文の転載は行いません。各記事の「情報源」に発行者・確認日・利用形態を表示します。"
                    )
                    section(
                        title: "優先すること",
                        body: "緊急時は、このアプリより消防・救急・自治体・現場の指示を優先してください。"
                    )
                    linksSection
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
            Text("約2週間の暮らしを整える、オフライン行動帳")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(readability.resolvedLineSpacing * 0.5)
                .fixedSize(horizontal: false, vertical: true)
            OfflineCapabilityBadge()
                .padding(.top, 2)
        }
        .accessibilityElement(children: .combine)
    }

    private var linksSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Web・サポート")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text("製品説明、サポート、プライバシーポリシーは公式サイトで確認できます。開くにはオンライン接続が必要です。")
                    .font(readability.prefersBoldBody ? .callout.weight(.medium) : .callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(readability.resolvedLineSpacing * 0.4)
                    .fixedSize(horizontal: false, vertical: true)

                linkRow(
                    title: "製品ページを開く",
                    subtitle: "hazakura.dev/14nichi-note",
                    url: Self.productURL
                )
                Divider()
                linkRow(
                    title: "サポート",
                    subtitle: "お問い合わせ・ヘルプ",
                    url: Self.supportURL
                )
                Divider()
                linkRow(
                    title: "プライバシーポリシー",
                    subtitle: "個人情報の取り扱い",
                    url: Self.privacyURL
                )
            }
        }
    }

    private func linkRow(title: String, subtitle: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .accessibilityHint("通信を使用して外部サイトを開きます")
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
