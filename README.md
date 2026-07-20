# 14日ノート

災害、停電、断水、通信障害などで日常生活が一時的に機能しなくなったとき、個人や家庭が次の行動をオフラインで確認するためのiPhone・iPad・Macアプリです。

フルMVPの機能実装と、内部TestFlight前のリポジトリ側提出準備まで完了しています（オフライン閲覧、探索、備蓄、緊急カード、公式リンク集、PDF・印刷、共有 Bundle ID、Mac Sandbox、Face ID 利用目的）。企画の原本は [`14日note.md`](./14日note.md)、実装範囲は [`docs/PROJECT_FOUNDATION.md`](./docs/PROJECT_FOUNDATION.md) を参照してください。AIエージェントは [`AGENTS.md`](./AGENTS.md) を確認し、提出手順は [`docs/RELEASE_SUBMISSION_CHECKLIST.md`](./docs/RELEASE_SUBMISSION_CHECKLIST.md) を正本にしてください。

## 現在の実装スライス

同梱したMarkdown記事を状況別に一覧表示し、通信なしで全文検索・カテゴリ・行動時期・お気に入りを組み合わせて閲覧できます。備蓄では7日・14日の必要量・不足・期限をSwiftDataへ保存し、買い物リストから在庫反映できます。緊急カードは脅威モデルで定めた最小の個人情報だけを、備蓄とは分離した端末内ストアへ保存します。公式情報リンク集と、項目選択・明示同意付きのPDF・印刷を備えます。同梱記事は制作フィクスチャの `draft` のままです。記事の本格拡充と監修は次フェーズです。

## 必要環境

- Xcode 26.6 以降（現在のローカル検証環境）
- Swift 6.2 以降
- XcodeGen 2.x
- iOS / iPadOS 18.0 以降
- macOS 15.0 以降

外部パッケージへの依存はありません。

## 開発開始

```sh
git status
swift test --disable-sandbox
swift run content-lint
xcodegen generate
open FourteenDayNote.xcodeproj
```

`FourteenDayNote.xcodeproj` は XcodeGen の生成物で Git 管理しません。クローン後は必ず `xcodegen generate` してください。

`content-lint` は同梱manifestとMarkdownの整合を検証します。App Store 提出前の配布ゲートは次です（現状の draft フィクスチャでは失敗します）。

```sh
swift run content-lint --distribution
```

生成した `FourteenDayNote.xcodeproj` はローカル生成物としてGit管理しません。Xcodeでは `FourteenDayNote`（iPhone / iPad）または `FourteenDayNoteMac` を選択します。Signing の Team は Xcode で選択し、`project.yml` に Team ID を推測で書かないでください。

## 安全上の境界

同梱中のサンプル記事は、表示と読み込みを確認するための制作フィクスチャです。防災・医療・食品衛生の正式コンテンツは、情報源（発行者・確認日・利用形態・権利注記）、対象地域、最終確認日、確認者、レビュー状態を揃え、公開前レビューを通過するまで製品コンテンツとして扱いません。長い原文の転載は行わず、公的一次情報への参照と自前の要約を原則とします。詳細は [`docs/CONTENT_CONTRACT.md`](./docs/CONTENT_CONTRACT.md) を参照してください。個人情報の扱いと最小項目は [`docs/EMERGENCY_CARD_THREAT_MODEL.md`](./docs/EMERGENCY_CARD_THREAT_MODEL.md) を正とします。
