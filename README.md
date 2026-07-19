# 14日ノート

災害、停電、断水、通信障害などで日常生活が一時的に機能しなくなったとき、個人や家庭が次の行動をオフラインで確認するためのiPhone・iPad・Macアプリです。

現在はオフライン閲覧基盤の実装段階です。企画の原本は [`14日note.md`](./14日note.md)、実装範囲と判断事項は [`docs/PROJECT_FOUNDATION.md`](./docs/PROJECT_FOUNDATION.md) を参照してください。AIエージェントは作業前に [`AGENTS.md`](./AGENTS.md) を確認してください。

## 最初の実装スライス

最初に完成させるのは、同梱したMarkdown記事を状況別に一覧表示し、通信なしで30秒以内に必要な記事を開ける閲覧基盤です。備蓄管理、緊急カード、PDF出力は、この基盤を実機で検証した後に追加します。

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

`content-lint` は同梱manifestとMarkdownの整合を検証します。任意でコンテンツディレクトリを渡せます。

```sh
swift run content-lint Sources/FourteenDayCore/Resources/Content
```

生成した `FourteenDayNote.xcodeproj` はローカル生成物としてGit管理しません。Xcodeでは `FourteenDayNote`（iPhone / iPad）または `FourteenDayNoteMac` を選択します。

## 安全上の境界

同梱中のサンプル記事は、表示と読み込みを確認するための制作フィクスチャです。防災・医療・食品衛生の正式コンテンツは、情報源（発行者・確認日・利用形態・権利注記）、対象地域、最終確認日、確認者、レビュー状態を揃え、公開前レビューを通過するまで製品コンテンツとして扱いません。長い原文の転載は行わず、公的一次情報への参照と自前の要約を原則とします。詳細は [`docs/CONTENT_CONTRACT.md`](./docs/CONTENT_CONTRACT.md) を参照してください。
