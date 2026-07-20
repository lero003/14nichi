# 14日ノート Agent Guide

## Read first

1. `README.md`
2. `docs/PROJECT_FOUNDATION.md`
3. `docs/CONTENT_CONTRACT.md`
4. `14日note.md`（企画の原本。実装済みとは限らない）

フルMVP完遂とTestFlight準備をまとめて依頼された場合は、追加で `docs/FULL_MVP_COMPLETION_BRIEF.md` を実行仕様として読んでください。

## Current lane

フルMVPを機能優先で実装中です。Slice 1「オフライン閲覧基盤」、Slice 2「探索性」、Slice 3「備蓄」は完了しています。次は `docs/FULL_MVP_COMPLETION_BRIEF.md` に従い、Slice 4「個人情報と出力」の実装前に、緊急カードの脅威モデル、最小データ、端末内保護、ロック時挙動、出力同意を文書で確定します。方針確定前に個人情報を保存しないでください。記事の本格拡充と監修、TestFlight準備はフルMVPの機能完成後です。

## Safety boundary

- `draft` / `reviewed` の記事を正式な安全情報として表現しない。
- 未監修フィクスチャへ、正しさを確認していない防災・医療・食品衛生上の指示を追加しない。
- `approved` には出典、最終確認日、確認者を必須とする現在の検証を弱めない。
- 情報源は `docs/CONTENT_CONTRACT.md` の権利方針に従う。長い原文転載、権利不明素材、httpリンクを入れない。
- 出典を付けるなら publisher・accessedAt・usage・rightsNote を揃える。`shortQuote` 以外に excerpt を置かない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
- 個人情報の保存は、専用スライスで脅威モデルと保護方針を確認するまで実装しない。お気に入りの記事IDや備蓄データとは分離する。
- 未監修の備蓄数量を推奨値として初期入力しない。数量は利用者入力とし、将来の正式な既定値はコンテンツ監修の対象にする。

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
