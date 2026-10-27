# App Store 申請素材

最終更新: 2026-10-27
状態: **v1.2差し替え準備中**。新ホーム、即応記事、備えの主要5点は旧 `1.1.0` / ビルド `7` のDebug Simulatorで撮影済み。2026-10-27のガイド改善（検索欄、記事内ジャンプ、読みやすさ導線）を反映し、v1.2最終Release候補で全点を再撮影する。

公開対象は **iPhone / iPad のみ**。Mac ターゲットはリポジトリに残すが、現行の App Store Connect レコードへ macOS プラットフォームは追加しない。

## v1.2で再撮影する画像

Apple の現行仕様に合わせ、アルファなし JPEG を提出用とする。PNG は撮影原本であり、Connect へはアップロードしない。

### iPhone 6.9インチ（1320 × 2868）

推奨順:

1. `screenshots/iphone-6.9/01-home.jpg` — 「いま困っている」と平時の準備が分かる新ホーム
2. `screenshots/iphone-6.9/02-first-actions.jpg` — 地震から1タップで開く最初の行動
3. `screenshots/iphone-6.9/03-stockpile-plan.jpg` — 家庭設定・不足品・買い物リストをつなぐ備え
4. `screenshots/iphone-6.9/04-emergency-card-privacy.jpg` — **再撮影待ち**。個人情報を入れていない緊急カードと端末内保護
5. `screenshots/iphone-6.9/05-private-pdf-export.jpg` — **再撮影待ち**。個人情報が既定オフのPDF・印刷

### iPad 13インチ（2064 × 2752）

推奨順:

1. `screenshots/ipad-13/01-home.jpg` — iPadの新ホーム
2. `screenshots/ipad-13/02-stockpile-calculator.jpg` — 家庭設定と不足品の備え
3. `screenshots/ipad-13/03-shopping-list.jpg` — **再撮影待ち**。不足品目だけの買い物リスト
4. `screenshots/ipad-13/04-emergency-card-privacy.jpg` — **再撮影待ち**。個人情報を入れていない緊急カード

## 文章素材

- `APP_STORE_CONNECT_JA.md` — 名前、サブタイトル、説明、キーワード、審査メモ、各種回答案
- `WEB_COPY_JA.md` — プライバシーポリシーとサポートページのアプリ固有本文

## 撮影条件

- iOS 27.0 Simulator
- iPhone 17 Pro Max / iPad Pro 13-inch (M5)
- 主要5点の現行画像は旧Debug Simulator build `1.1.0 (7)`。Connect投入前に全点を `1.2.0` の最終Release候補で再撮影する
- 時刻 9:41、バッテリー100%、Wi-Fi表示
- 緊急カードは未入力。個人情報・実在の連絡先は含まない
- 商品機能をそのまま撮影し、説明用の合成や未実装機能の追加はしていない

既存JPEGをv1.2へそのまま提出しない。新ホーム、5タブ構成、備え内の買い物導線、ガイドの検索・記事内ジャンプ、読みやすさ導線を含む最終Release候補を実機相当サイズで撮影し、画像と実装が一致してからConnectへアップロードする。

## アップロード前の最終確認

- JPEGだけを使う（PNG原本はアルファチャンネルあり）
- iPhone / iPadそれぞれで順番を確認する
- 最新ビルドのUIと画像が一致していることを確認する
- URL、問い合わせ先、Copyright、審査連絡先は本人の確定値を入力する
