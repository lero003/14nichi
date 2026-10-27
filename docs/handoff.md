# Handoff

## Current State

- **2026-07-24: iOS App Store 審査通過・初回公開**（`1.0.0` / ビルド `6`、iPhone / iPad）。Git タグ `v1.0.0`。
- `main` は **iOS `1.2.0` / ビルド `7` の提出前候補**。未提出のv1.1機能スライス、2026-08-14の記事・出典更新、2026-10-27の防災ガイド改善を統合済み。
- 公開範囲は **iPhone / iPadのみ**。Macターゲットはリポジトリに残すが、現行商品ページ・公開対象には含めない。
- フルMVP機能完了（オフラインガイド、探索、備蓄、緊急カード、公式リンク、PDF・印刷、Face ID 利用目的、暗号化 Infop、Privacy Manifest）。
- 同梱13状況・30記事はすべて `approved`。公的一次情報照合・編集確認済みで、専門資格監修や正確性保証ではない旨を常時表示。
- サポート / プライバシーは About と「その他」タブから開ける。本番URLは `https://hazakura.dev/14nichi-note/` 系。
- 申請用スクショと日本語メタデータは `docs/app-store-assets/`。変更履歴は `CHANGELOG.md`。

## Recent Changes

- 2026-10-27: 防災ガイドを改善。ガイド先頭に検索欄を常時表示（`.navigationBarDrawer`指定がないとiOS 27 Simulatorで検索UIが出ないことを確認して修正）、記事内に「記事の構成」ジャンプを追加、状況一覧・記事詳細からも読みやすさ/Aboutを開けるようにした。検索結果・お気に入りには所属状況を表示。避難ショートカットはmanifestの`shortcutArticleID`で「避難するか、留まるか」へ固定。状況一覧の重複見出し、全行の「正式版」表示、ガイドヒーローの文言・指標を整理。Simulator確認用に`--screenshot-route=`を追加（DEBUG）。あわせて14記事のmanifestタイトルと本文H1を統一し、ローダーで一致を検証。iPad分割表示の選択行をカスタム表示へ変更して白文字化を解消し、ダークモードの正式版・補助文言を適応色へ。ガイドのiPad空状態には状況一覧を開くボタンを追加。
- 2026-08-14: iOS版を `1.2.0` / ビルド `7` の提出前候補へ更新。同梱記事と36出典URLを再照合し、水害・避難3記事へ令和8年5月開始の防災気象情報（レベル付き警報、キキクル、避難指示がなくても自ら判断）を追加。余震記事のガス臭時に電気スイッチ禁止をガス記事と揃え、低体温の保温表現を消防庁・日赤の個別ページへ直接追跡できる内容に整理。日赤止血URLと厚労省水道URLを現行到達先へ更新し、公式リンク集へ新気象情報とキキクルを追加。
- 2026-07-26自己レビュー: 空にした緊急カードの準備状態を未確認へ戻し、関連記事の同順位をmanifest順に固定。v1.1提出資料のビルド番号・再撮影状態も現在候補へ揃えた。
- 2026-07-26: 初期画面をホームへ変更し、地震・停電・断水・大雨／洪水・ケガ／体調不良・避難から `approved` / `critical` / `immediate` 記事へ1タップで進めるようにした。
- タブを「ホーム / ガイド / 備え / 緊急 / その他」へ変更し、買い物リストを備えの子画面へ統合。備えと買い物の双方向導線を追加した。
- `AppRouter`でタブと記事・状況・備え・買い物・緊急カードのルートを型付きにした。iPhoneのNavigationStackとiPadの既存Split Viewで同じ指定を使う。
- `PreparednessChecklistStore`を追加。保存するのは3項目の確認日時とカードの「保存した／今回は使わない」選択だけで、カード本文は読まない。
- 記事と同じ先頭H1を表示時だけ省略し、お気に入りをツールバーへ移動。同じ状況の関連記事を最大3件表示する。
- v1.1の計画・ロードマップ・App Store文面・手動スモーク手順を追加／更新。新ホーム、地震記事、備えの主要5画像をSimulatorから再撮影した。
- 2026-07-24: App Store 審査通過をドキュメントに反映し、`CHANGELOG.md` とタグ `v1.0.0` を追加。
- 「その他」タブからサポート・プライバシーへ直接リンクできるようにし、URL定数を共通化した。
- iOS/Mac の Bundle ID を `jp.hazakura.FourteenDayNote` に統一した履歴あり。2026-07-22に初回申請からMacを外したため、同一商品ページ方針は現在不採用。
- `NSFaceIDUsageDescription` と `ITSAppUsesNonExemptEncryption=false` を追加。
- Mac に App Sandbox entitlements を追加（user-selected file 権限は未付与）。
- PrivacyInfo が XcodeGen で除外されていた問題を修正し Resources に含めた。
- `docs/RELEASE_SUBMISSION_CHECKLIST.md` に提出〜公開の内部手順を整理。
- 秘匿プレースホルダまで透明になる不具合を修正し、アプリ内ロック有効時は非アクティブ移行で解除状態を破棄するようにした。
- PDFの共有名を `14nichi-export.pdf` に固定し、UUID専用ディレクトリごと後片付けするようにした。認証前は個人情報プレビューを組み立てない。
- 備蓄の詳細入力（年齢区分、1日量、現在量、期限）を主導線から除去。水3L・食料3食・携帯トイレ5回分（各1人1日）だけを出典付き目安として自動計算する。
- SwiftDataをV2へ更新し、旧V1の不足・準備済み状態を新しい不足選択・購入済み状態へ一度だけ変換する。
- 状況・記事を13状況・30記事へ拡充し、検索・絞り込み・ナビゲーションを更新。津波の即時避難と119/AED/胸骨圧迫の記述は該当する気象庁・消防庁一次情報へ合わせた。
- 数量根拠のある水・食料・携帯トイレと、数量を家庭で決める生活用品チェックリストを分離した。
- App Store配布で検出されたApp Iconのアルファを除去。家・ノート・14日チェックを統合した新デザインへ全11サイズを差し替え、再提出候補を `0.1.0 (2)` に更新した。
- アイコン由来の配色トークンとブランドマークを共通化。ガイド先頭へ役割と収録件数が分かるヘッダーを追加し、状況・記事・備蓄・買い物・緊急カードの表現を統一した。大きな文字ではマークと指標が収まるよう自動調整する。
- 30記事を公的一次情報と再照合して `approved` 化。避難情報、食品、熱中症、ガス、止血、低体温、救急相談、常用薬に直接出典を補い、全記事へ情報の限界と公式情報優先の注意事項を追加した。
- 文字サイズを5段階・標準初期値へ整理し、行間を広げた。About/読みやすさを単一sheetにしてiPhone Airの情報ボタン経由クラッシュを防ぎ、「14日ノートとは」を追加した。
- About に製品ページ（https://hazakura.dev/14nichi-note/）・サポート・プライバシーへのオンラインリンクを追加した。
- 記事詳細の注意事項を、上部の短いバナー＋本文後の詳細説明に再配置。Markdown本文の重複注意と「公式情報・出典」定型節を削除し、各記事の行動手順を拡充した。
- TestFlight（0.1.0/5）で i ボタン押下時に About sheet が `ReadabilitySettings` の Environment 欠落で SIGTRAP クラッシュする不具合を修正。sheet コンテンツへ `.environment(model.readability)` を明示注入。
- 審査前の全体再監査で、緊急カード記事を脅威モデルの採用項目へ一致させ、ガス臭・断水時の飲用と手指衛生を一次情報に沿って修正。PDF生成失敗時と前回異常終了時の一時ファイル削除も追加した。

## Decisions

- 初回App Store申請はiPhone / iPadのみ。Mac版の商品構成は将来の再レビューまで決めない。
- Team ID は `project.yml` に書かない。
- 一般公開候補は `content-lint --distribution` 必須。`approved` は編集確認状態であり専門資格監修とは表現しない。
- Aboutに設定済みの製品・サポート・プライバシーURLは、提出直前に本人が公開アクセスと問い合わせ先を確認する。
- 食品は合計食数までとし、缶詰・乾パン等の個数配分は公的一律根拠がないため自動計算しない。

## Tests

- `swift test --disable-sandbox`: **84 tests / 14 suites 成功**（2026-10-27、ガイド改善後）。
- `swift run --disable-sandbox content-lint` / `--distribution`: 成功（13状況・30記事、全件 `approved`）。
- `xcodegen generate`: 成功。生成プロジェクトで **`1.2.0 (7)`** を確認（2026-10-27）。
- `FourteenDayNote` generic iOS Simulator Debug / Release unsigned build: **`1.2.0 (7)` で成功**。
- iPhone 17 / iOS 27.0 SimulatorのXCUITest: **8件成功**（検索、記事内ジャンプ、読みやすさ、避難ショートカット、ホーム、備え→買い物、ガイド復帰）。
- ガイド・状況一覧・記事詳細・ホームをiPhone 17 / iOS 27 Simulatorで目視確認。App Store画像の再撮影は未実施。
- v1.2のArchive / Validate / Upload: **未実施**（本人がXcode側で実施）。
- 生成appで Bundle ID `jp.hazakura.FourteenDayNote`、`1.2.0 (7)`、Face ID文、暗号化フラグfalse、Privacy Manifest同梱を確認。
- AppIcon source 11枚: 指定ピクセル寸法、RGB PNG、`hasAlpha: no` を確認。iOS / Mac Asset Catalogを含むRelease unsigned build成功。
- 過去: 75 tests / 13 suites（2026-08-14、記事・出典更新後）、66 tests / 12 suites（V1永続ストアからV2への実移行とPDF一時ディレクトリ削除）、`1.0.0 (6)` Release（2026-07-24）。
- Mac Releaseは過去に成功しているが、今回の申請対象外のため最終調整後は再検証していない。

## Risks / Unknowns

- iPhone / iPad実機での機内モード30秒、VoiceOver、最大Dynamic Type、Reduce Motion、ダークモード、App Switcher秘匿、認証、PDF共有は未確認。
- 記事内ジャンプは見出しを画面中央付近へ移動する（ナビゲーションバー直下への固定ではない）。実機で位置とVoiceOverの読み上げ順を確認する。
- 「記事の構成」は最大Dynamic Typeで2〜3行に折り返す。実機でのタップ領域と折り返しを確認する。
- 初見利用者5人の目的理解・10分準備フロー観察は未実施。
- App Store画像は旧v1.1候補のままで、v1.2のガイド改善を反映した全点の再撮影が必要。
- Archive / Validate / Upload / App Store Connect入力・提出は未実施。
- 公開後フィードバックとコンテンツ鮮度の継続監視が必要。2026-08-14に水害・避難・余震・低体温と一部出典URLを再確認したが、専門資格監修は未実施。
- 失効 Development 証明書（lero003）が identity に残存する環境では使わない。
- 専門資格者による個別監修は未実施。編集確認済みという境界を維持する。
- Mac版の商品構成・Bundle ID・保存領域は、配布を実際に進めるときに再レビューする。

## Next Actions

1. v1.2をiPhone / iPad実機で `docs/MANUAL_SMOKE_CHECKLIST.md` に沿って確認する。
2. 初見利用者5人の観察テストを実施し、4人以上の基準を記録する。
3. App Store画像を最終Release候補で全点撮影し、Connect文面を本人が最終確認する。
4. `docs/RELEASE_SUBMISSION_CHECKLIST.md` に沿ってArchive / Validate / Upload / 提出する。Connectに後続ビルドがあればビルド番号を上げる。

## Avoid

- 公開済み Bundle ID を安易に変えない。
- `approved` を専門資格監修済み、またはあらゆる状況で正確と表現しない。
- 公開済みタグ `v1.0.0` を動かさない。修正は新コミットと必要なら次バージョンで行う。
- Upload や Team 固定をエージェントが独断しない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
