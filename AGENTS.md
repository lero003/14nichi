# 14日ノート Agent Guide

## Read first

1. `README.md`
2. `docs/PROJECT_FOUNDATION.md`
3. `docs/CONTENT_CONTRACT.md`
4. `14日note.md`（企画の原本。実装済みとは限らない）

## Current lane

現在は Slice 1「オフライン閲覧基盤」です。状況選択、同梱コンテンツの検証、Markdown表示、アクセシビリティを小さく完成させます。備蓄管理、個人情報、同期、PDF、課金は先取りしません。

## Safety boundary

- `draft` / `reviewed` の記事を正式な安全情報として表現しない。
- 未監修フィクスチャへ、正しさを確認していない防災・医療・食品衛生上の指示を追加しない。
- `approved` には出典、最終確認日、確認者を必須とする現在の検証を弱めない。
- 情報源は `docs/CONTENT_CONTRACT.md` の権利方針に従う。長い原文転載、権利不明素材、httpリンクを入れない。
- 出典を付けるなら publisher・accessedAt・usage・rightsNote を揃える。`shortQuote` 以外に excerpt を置かない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
- 個人情報の保存は、別スライスで脅威モデルを確認するまで実装しない。

## Development loop

1. 変更前に現在の資料と対象コードを読む。
2. 1つの検証可能な変更へ絞る。
3. `swift test --disable-sandbox` を実行する。
4. コンテンツを触った場合は `swift run content-lint` も実行する。
5. `project.yml` を変えた場合は `xcodegen generate` を実行する。
6. 選択したschemeを明示してXcode buildを確認する（現状は `FourteenDayNoteMac` が安定）。
7. 実装境界や次の優先順位が変わった場合だけ `docs/PROJECT_FOUNDATION.md` を更新する。

`FourteenDayNote.xcodeproj` は生成物です。直接編集せず、`project.yml` を変更してください。

## Review handoff

レビュー依頼には、目的、変更ファイル、実行した検証、未検証事項、コンテンツの監修状態を含めてください。近接する別機能を一緒に実装しないでください。

