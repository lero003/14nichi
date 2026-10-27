# レビュー依頼: 防災ガイド改善と v1.2 提出前候補

最終更新: 2026-10-27
対象: `main`（iOS `1.2.0` / ビルド `7` 提出前候補）

## 目的

公開済み `1.0.0` の次の更新版に向けて、防災ガイドの「緊急時に迷わず読める」導線を改善する。あわせて、着手前から作業ツリーにあった 2026-08-14 の同梱記事・出典更新とバージョン更新を同じ提出前候補としてまとめる。

## 変更の要約

- **検索**: ガイド先頭の検索欄が iOS 27 Simulator で表示されなかったため、`.searchable` を一覧へ直接付け、`navigationBarDrawer` を明示した。
- **記事内ジャンプ**: 記事本文の見出し（最初の5分、今日中、明日以降、やってはいけない、状況が悪化、限界）を「記事の構成」チップから移動できるようにした。アンカーは目次ボタンのIDと衝突しないよう `article-block-<index>` に名前空間化した。
- **読みやすさ導線**: 状況一覧・記事一覧・記事詳細のツールバーから「読みやすさ」「このアプリについて」を開けるようにした。ガイドのルートでは絞り込みメニューを出さない。
- **状況の手がかり**: 検索結果・お気に入りに、記事が属する状況名を表示する。
- **ショートカット**: manifest の `shortcutArticleID` を追加し、「避難を考える」が持ち出し袋ではなく「避難する・留まるの判断」を開くようにした。状況の記事一覧でも同じ記事を先頭に出す。
- **タイトル整合**: manifest の title と本文先頭H1が違う14記事を統一し、ローダーで一致を検証するようにした。記事詳細のタイトル二重表示を解消。
- **表示整理**: 状況一覧の見出し重複、全行の「正式版」繰り返し、ガイドヒーローの文言・指標を整理。
- **iPad / ダークモード**: 分割表示の選択行をカスタムカード表示に変更して白文字化を解消。ダークモードで読めなかった「正式版」「今回は使わない設定」などを適応色へ変更。iPadの空状態に「状況の一覧を開く」を追加。
- **開発用**: Simulator確認用の `--screenshot-route=` を追加（DEBUGのみ）。

## 主な変更ファイル

- Core: `Sources/FourteenDayCore/GuideArticle.swift`, `ArticleDiscovery.swift`, `ContentRepository.swift`, 新規 `ArticleOutline.swift`
- コンテンツ: `Sources/FourteenDayCore/Resources/Content/manifest.json`（タイトル統一、`shortcutArticleID`）、`Resources/Content/emergency/*.md`（2026-08-14の内容更新）、`Resources/OfficialLinks/official-links.json`
- UI: `Sources/FourteenDayNoteApp/ArticleBrowserView.swift`, `ArticleDetailView.swift`, `ArticleMarkdownView.swift`, `Components.swift`, `HomeView.swift`, `MainTabView.swift`, `AppModel.swift`, 新規 `WrapLayout.swift`
- テスト: `Tests/FourteenDayCoreTests/ContentRepositoryTests.swift`, `ArticleDiscoveryTests.swift`, 新規 `GuideArticleOutlineTests.swift`, `Tests/FourteenDayNoteUITests/FourteenDayNoteUITests.swift`
- ドキュメント: `CHANGELOG.md`, `README.md`, `docs/PROJECT_FOUNDATION.md`, `docs/handoff.md`, `docs/CONTENT_CONTRACT.md`, `docs/MANUAL_SMOKE_CHECKLIST.md`, `docs/ROADMAP.md`, `docs/V1_1_PRODUCT_PLAN.md`, `docs/app-store-assets/APP_STORE_CONNECT_JA.md`, `docs/app-store-assets/README.md`
- ビルド設定: `project.yml`（マーケティング `1.2.0` / ビルド `7`）

注: 着手前から作業ツリーにあった 2026-08-14 の記事・出典更新、バージョン更新、関連ドキュメント更新も同じコミットに含まれる。

## 実行した検証

- `swift test --disable-sandbox`: **84 tests / 14 suites 成功**（2026-10-27）
- `swift run --disable-sandbox content-lint --distribution`: **成功（13状況・30記事、全件 `approved`）**
- `xcodegen generate`: 成功
- `xcodebuild test`（iPhone 17 / iOS 27.0 Simulator）: **8 UIテスト成功**
  - ホーム→地震記事、避難ショートカット→判断記事、ガイド検索、記事内ジャンプ、記事の読みやすさ、状況一覧の絞り込み/読みやすさ、備え→買い物、ガイド復帰
- `xcodebuild` generic iOS Simulator **Debug / Release unsigned**: 成功。生成物は **`1.2.0 (7)`**
- iPhone 17 / iOS 27.0 Simulatorでライト/ダーク、ガイド、状況一覧、記事詳細、避難ショートカットを目視確認。iPad Pro 11-inch / iOS 27.0 Simulatorで分割表示、選択行、空状態ボタンを確認（横向きは未確認）。空状態の「状況の一覧を開く」は一時UIテストでも動作確認
- `xcodebuild` の警告は AppIntents メタデータ抽出スキップのみ

## 未検証・残るゲート

- iPhone / iPad 実機での機内モード30秒、VoiceOver、最大 Dynamic Type、Reduce Motion、App Switcher 秘匿、認証、PDF共有
- iPad 横向きの3カラム表示（今回のスクリーンショットは縦向き）
- 記事内ジャンプの見出し位置は画面中央寄せ。実機で読み上げ順とスクロール位置を確認したい
- App Store 画像は旧 `1.1.0` 候補のままで、全点の再撮影が必要
- Archive / Validate / Upload / App Store Connect 入力・提出は未実施
- 初見利用者5人の観察テストは未実施

## コンテンツの確認状態

- 30記事はすべて `approved`。2026-08-14 に公的一次情報と照合・編集確認済み。
- 今回の変更は、記事本文の安全上の主張を書き換えていない。記事タイトルの表記統一、manifest のショートカット指定、UI表示の変更が中心。
- `approved` は専門資格者による個別監修や正確性保証ではない、という境界を維持している。
- `shortcutArticleID` は `approved` / `immediate` / その状況に属する記事だけを許可する検証を追加した。
- manifest の title と本文先頭H1の一致をローダーで検証するようにした（14記事を統一）。

## 重点レビュー観点

1. `shortcutArticleID` の検証とフォールバックが、既存の critical/immediate ルールを壊していないか。
2. manifest title と H1 の一致検証が、将来の記事追加・ローカライズに対して厳しすぎないか。
3. `ArticleOutline` のスクロールアンカーと `WrapLayout` のアクセシビリティ（VoiceOver / 最大文字サイズ）。
4. ガイドのツールバー配置（状況一覧・記事一覧・記事詳細）が、iPhone / iPad / Mac で矛盾しないか。
5. iPad 分割表示を `List(selection:)` から Button + カスタム選択表示へ変えたことで、キーボード操作やアクセシビリティ上の退行がないか。
6. ダークモードの配色（特に `AppTheme.deepTeal` を残した箇所）が十分なコントラストか。
7. 検索欄の `.navigationBarDrawer` 指定が iOS 18〜27 で妥当か。

## 既知のリスク

- 記事内ジャンプは `anchor: .center` のため、見出しが画面上部に固定されない。
- iPad 縦向きではサイドバーが初期状態で折りたたまれ、記事列に「状況の一覧を開く」ボタンを出している。横向きの挙動は未確認。
- 既存の公開済みタグ `v1.0.0` は動かしていない。
