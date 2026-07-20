# 14日ノート Agent Guide

## Read first

1. `README.md`
2. `docs/PROJECT_FOUNDATION.md`
3. `docs/CONTENT_CONTRACT.md`
4. `14日note.md`（企画の原本。実装済みとは限らない）

フルMVP完遂とTestFlight準備をまとめて依頼された場合は、追加で `docs/FULL_MVP_COMPLETION_BRIEF.md` を実行仕様として読んでください。個人情報を触る前に `docs/EMERGENCY_CARD_THREAT_MODEL.md` を確認してください。

## Current lane

フルMVP機能（Slice 1〜4、公式リンク集、PDF・印刷）は実装済みです。次は iOS Platform 導入と実機スモーク、内部TestFlightの本人操作（Team / Archive / Upload）、その後の記事拡充・監修フェーズです。手順は `docs/MANUAL_SMOKE_CHECKLIST.md` と `docs/TESTFLIGHT_HANDOFF.md` を参照してください。

## Safety boundary

- `draft` / `reviewed` の記事を正式な安全情報として表現しない。
- 未監修フィクスチャへ、正しさを確認していない防災・医療・食品衛生上の指示を追加しない。
- `approved` には出典、最終確認日、確認者を必須とする現在の検証を弱めない。
- 情報源は `docs/CONTENT_CONTRACT.md` の権利方針に従う。長い原文転載、権利不明素材、httpリンクを入れない。
- 出典を付けるなら publisher・accessedAt・usage・rightsNote を揃える。`shortQuote` 以外に excerpt を置かない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
- 個人情報は脅威モデルの採用項目だけを、備蓄・お気に入りと分離したストアへ保存する。iCloud同期や外部送信を追加しない。
- 未監修の備蓄数量を推奨値として初期入力しない。数量は利用者入力とし、将来の正式な既定値はコンテンツ監修の対象にする。
- App Store 提出前は `swift run content-lint --distribution` が通る状態（全記事 approved）を要求する。内部TestFlightの draft フィクスチャとは分ける。

## Development loop

1. 変更前に現在の資料と対象コードを読む。
2. 1つの検証可能な変更へ絞る。
3. `swift test --disable-sandbox` を実行する。
4. コンテンツを触った場合は `swift run content-lint` も実行する。
5. `project.yml` を変えた場合は `xcodegen generate` を実行する。
6. 選択したschemeを明示してXcode buildを確認する（現状は `FourteenDayNoteMac` が安定。iOSは Platform 導入後）。
7. 実装境界や次の優先順位が変わった場合だけ `docs/PROJECT_FOUNDATION.md` を更新する。

`FourteenDayNote.xcodeproj` は生成物です。直接編集せず、`project.yml` を変更してください。`DEVELOPMENT_TEAM` を推測で `project.yml` に書かないでください。

## Review handoff

レビュー依頼には、目的、変更ファイル、実行した検証、未検証事項、コンテンツの監修状態を含めてください。近接する別機能を一緒に実装しないでください。
