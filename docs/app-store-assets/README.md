# App Store 申請素材

最終更新: 2026-07-22

初回申請対象は **iPhone / iPad のみ**。Mac ターゲットはリポジトリに残すが、今回の App Store Connect レコードへ macOS プラットフォームは追加しない。

## そのままアップロードする画像

Apple の現行仕様に合わせ、アルファなし JPEG を提出用とする。PNG は撮影原本であり、Connect へはアップロードしない。

### iPhone 6.9インチ（1320 × 2868）

推奨順:

1. `screenshots/iphone-6.9/01-guide.jpg` — 状況別オフラインガイド
2. `screenshots/iphone-6.9/02-first-actions.jpg` — 最初の行動と安全情報の注意事項
3. `screenshots/iphone-6.9/03-stockpile-plan.jpg` — 人数・7日/14日の備蓄計画
4. `screenshots/iphone-6.9/04-emergency-card-privacy.jpg` — 個人情報を入れていない緊急カードと端末内保護
5. `screenshots/iphone-6.9/05-private-pdf-export.jpg` — 個人情報が既定オフのPDF・印刷

### iPad 13インチ（2064 × 2752）

推奨順:

1. `screenshots/ipad-13/01-guide-and-article.jpg` — 状況・記事一覧・本文の3カラム
2. `screenshots/ipad-13/02-stockpile-calculator.jpg` — 3人・14日分の数量目安
3. `screenshots/ipad-13/03-shopping-list.jpg` — 不足品目だけの買い物リスト
4. `screenshots/ipad-13/04-emergency-card-privacy.jpg` — 個人情報を入れていない緊急カード

## 文章素材

- `APP_STORE_CONNECT_JA.md` — 名前、サブタイトル、説明、キーワード、審査メモ、各種回答案
- `WEB_COPY_JA.md` — プライバシーポリシーとサポートページのアプリ固有本文

## 撮影条件

- iOS 26.5 Simulator
- iPhone 17 Pro Max / iPad Pro 13-inch (M5)
- Release Simulator build `0.1.0 (2)`
- 時刻 9:41、バッテリー100%、Wi-Fi表示
- 緊急カードは未入力。個人情報・実在の連絡先は含まない
- 商品機能をそのまま撮影し、説明用の合成や未実装機能の追加はしていない

画像撮影後、既存TestFlightより新しい提出候補としてiOSの版番号を `1.0.0 (6)` へ更新した。版番号は画像内に表示されず、画面機能とレイアウトは同じため、このJPEGを提出用として使用する。

## アップロード前の最終確認

- JPEGだけを使う（PNG原本はアルファチャンネルあり）
- iPhone / iPadそれぞれで順番を確認する
- 最新ビルドのUIと画像が一致していることを確認する
- URL、問い合わせ先、Copyright、審査連絡先は本人の確定値を入力する
