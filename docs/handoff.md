# Handoff

## Current State

- Slice 1のオフライン閲覧基盤は、4状況 / 5件の未監修フィクスチャで操作できる。
- 2026-07-20のレビュー修正は作業ツリー上にあり、まだコミットされていない。

## Recent Changes

- 端末のDynamic Typeがアプリ設定より大きい場合、そのサイズを縮小しないようにした。
- 起動時の意図的な280ms待機を削除し、同梱コンテンツをすぐ読み込むようにした。
- Markdownを意味のあるブロックへ分け、本文見出しをVoiceOverの見出しとして公開した。
- Reduce Motion、巨大文字での行レイアウト、重複ツールバー、状況外の記事選択を修正した。
- 情報源から公式サイトを開けるオンライン表記付きリンクを追加した。
- 出典の確認日を、書式だけでなく実在するGregorian日付として検証するようにした。

## Decisions

- アプリ内文字サイズは端末設定を上書きする値ではなく、読みやすさの下限として扱う。
- オフライン本文の閲覧はアプリ内で完結させ、外部通信は情報源の明示的なリンク操作に限る。
- 未監修フィクスチャを実際の緊急時手順に見える文面へ広げない。

## Tests

- `swift test --disable-sandbox`: 16 tests / 2 suites 成功。
- `swift run --disable-sandbox content-lint`: 4 situations / 5 articles、成功。
- `xcodegen generate`: 成功。
- `FourteenDayNoteMac` の未署名Debug build: 成功。

## Risks / Unknowns

- iOS Platformがローカルにないため、iOSビルド・シミュレータ・VoiceOver実機確認は未実施。
- Markdownブロックパーサーは現在の記事形式（見出し、段落、箇条書き、引用）に限定している。

## Next Actions

- iPhone実機またはシミュレータで、完全オフライン起動、最大文字サイズ、VoiceOver見出し移動を確認する。
- 状況選択と記事選択のUIテストを追加する。

## Avoid

- 監修前の記事を正式な防災・医療・食品衛生情報として扱わない。
- 端末のアクセシビリティ文字サイズをアプリ設定で縮小しない。
