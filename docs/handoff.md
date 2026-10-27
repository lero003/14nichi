# Handoff

最終更新: 2026-10-27

## Current State

- 現在の公開版: iOS/iPadOS `1.2`（公開レコード `1.2`、選択ビルド `1.2.0 (8)` を2026-10-27にApp Store Connectで確認。公開日は未確認）。
- 初回公開の履歴: `1.0.0 (6)`、2026-07-24審査通過、タグ `v1.0.0`。
- 現在: `1.3.0 (9)` を内部TestFlightへ配信済み。配信元はcleanな `58d63e0`（origin/mainへpush済み）。Archive/Validate/Upload・Apple処理完了・既存内部グループ `test`（1名）への追加を確認。App Store審査は未提出。
- 同梱13状況・30記事は全件approved。今回全本文を読了し、本文10記事と出典を修正。出典追加/差替を含め13記事の確認日・確認者を更新。
- 公開対象はiPhone/iPad。Macターゲットは将来候補。
- 正本: `PROJECT_FOUNDATION.md`、`CONTENT_CONTRACT.md`、`RELEASE_SUBMISSION_CHECKLIST.md`。今回の確認範囲・出典・未取得資料は `REVIEW_RESULTS_2026-10-27.md`。

## Recent Changes

- 停電の逆指示、家具を壁から離す指示、発電機の屋内禁止条件、CO中毒疑い時の119番、加熱不可/保存温度不良の食品、断水後の飲用、避難レベルと在宅条件、機内モード受信停止を修正。
- 農水省2026-09-08の災害食品安全などの直接根拠を追加し、旧厚労省水道窓口を環境省へ差替。衛生・デマの記事にも直接根拠を補充。
- `shortcutArticleID` のtrim検証と生値解決の不整合を解消。不正な前後空白/改行/空文字を拒否。
- 画面幅変更時の記事別読書位置をブラウザのメモリに保持。ジャンプと位置復元を同じscrollPositionへ揃えた。regularの選択をcompactルートへ同期。
- ジャンプ後のVoiceOverフォーカスを見出しへ連携、チップの最小タップ高44pt、最優先バッジ/ヒーロー小文字のコントラストを改善。
- DEBUG限定の可変幅回帰ホストとUIテスト3件。通常起動/Releaseには検証UIを表示しない。

## Decisions

- 記事増加・全面改稿は不要。新防災気象情報体系は既存記事と現行気象庁資料で整合。
- approvedは編集確認であり、専門資格者による個別監修や状況ごとの正確性保証ではない。今回の確認者にはCodexと明記。
- 確認日は記事・出典ごと。旧引継ぎの「全30記事8/14確認」はmanifestと一致しない。未取得出典の日付を一括更新しない。
- titleと先頭H1の完全一致、ショートカットのapproved/所属状況/immediate条件を維持。
- 読書位置はメモリ内だけ。永続ストア、備蓄数量の計算、個人情報項目、ネットワーク/SDKは変更しない。
- 水3L・食料3食・携帯トイレ5回分/人日以外の根拠のない品目配分を追加しない。

## Tests

以下は独立レビュー時の `1.2.0 (7)` の記録。現在候補 `1.3.0 (9)` の配信検証は `TESTFLIGHT_1_3_0.md` を参照。

- `swift test --disable-sandbox`: **85 tests / 14 suites成功**。
- `swift run content-lint` / `--distribution`: **13状況・30記事、全件approved**。
- `xcodegen generate`: 成功。`FourteenDayNote` generic iOS Simulator Debug/Release unsigned build成功。
- iPhone 17 / iOS 27.0: 既存XCUITest **8件成功**。
- iPad Pro 11-inch (M4) / iOS 27.0: 可変幅回帰 **3件成功**（ジャンプ先、手動読書位置、検索と結果復帰）。
- Release生成物でBundle ID、1.2.0 (7)、SDK27.1、device families、横向き、Privacy Manifestを確認。
- iPhone Simulatorの最大文字/darkで記事上部を目視確認。実機アクセシビリティ確認は残。
- `git diff --check`成功。統合レビューで追加ブロッカーなし。
- AppIntents抽出スキップ、XcodeのSDK build番号/debugger lookup診断がある。詳細はレビュー結果。

- `1.3.0 (9)` のArchive/export、ローカル署名/プロファイル照合、Apple側Validate/Uploadと処理完了を確認。IPAのSHA-256と配信元コミットは `TESTFLIGHT_1_3_0.md`。
- 1.2.0(8)の次に1.3.0(9)を配信し、既存内部グループ `test` へ自動追加。日本語テスト内容も保存済み。

## Risks / Unknowns

- Duoのdevice typeはあるがiOS 27.1 runtime未導入。取得は低速のため中断。iPadの幅変更テストは実Duoの開閉/pose/非対称セーフエリアの証拠ではない。
- iOS 18の実行確認、実機VoiceOver（ジャンプ先含む）、最大文字の全画面、Reduce Motion、iPad外付けキーボードは未実施。
- 機内モード30秒、App Switcher秘匿、認証、PDF共有などの実機ゲートは未実施。
- 政府広報旧preparation URLとMETIガス臭ページは直接取得403、厚労省低体温PDFは取得上限。旧accessedAt維持。他の取得済み一次資料と区別。
- App Store画像は旧候補。最終Release候補の全点再撮影が必要。
- ビルド9のArchive/Validate/Upload・Apple処理・内部配信は確認済み。App Store審査提出と初見5人観察は未実施。

## Next Actions

1. 内部TestFlightの1.3.0(9)を実機で確認し、`MANUAL_SMOKE_CHECKLIST.md` の結果を記録。App Store提出はその後に `RELEASE_SUBMISSION_CHECKLIST.md` に従う。
2. TestFlightで `MANUAL_SMOKE_CHECKLIST.md` のDuo/実機/アクセシビリティを実施し、端末・OS・結果を記録する。
3. 一般公開提出の前に最終Release候補のApp Store画像とConnect文案を確認する。

## Avoid

- 公開済みBundle ID・タグを変更しない。Team IDを推測でproject.ymlへ固定しない。
- 生成xcodeprojを直接編集しない。schemaや個人情報ストアを保守スライスへ混ぜない。
- Upload・公開・実機合格をローカルビルドやSimulator成功と同一視しない。
- approvedの意味を拡張しない。出典取得失敗を、リンク切れや再確認成功と断定しない。
