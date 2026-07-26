# Handoff

## Current State

- **2026-07-24: iOS App Store 審査通過・初回公開**（`1.0.0` / ビルド `6`、iPhone / iPad）。Git タグ `v1.0.0`。
- `main` は **iOS `1.1.0` / ビルド `7` の提出前候補**。新ホーム、緊急ショートカット、3項目の準備チェック、備え内の買い物リスト、記事UXの簡潔化を実装済み。
- 公開範囲は **iPhone / iPadのみ**。Macターゲットはリポジトリに残すが、現行商品ページ・公開対象には含めない。
- フルMVP機能完了（オフラインガイド、探索、備蓄、緊急カード、公式リンク、PDF・印刷、Face ID 利用目的、暗号化 Infop、Privacy Manifest）。
- 同梱13状況・30記事はすべて `approved`。公的一次情報照合・編集確認済みで、専門資格監修や正確性保証ではない旨を常時表示。
- サポート / プライバシーは About と「その他」タブから開ける。本番URLは `https://hazakura.dev/14nichi-note/` 系。
- 申請用スクショと日本語メタデータは `docs/app-store-assets/`。変更履歴は `CHANGELOG.md`。

## Recent Changes

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

- `swift test --disable-sandbox`: **75 tests / 13 suites 成功**（2026-07-26）。
- `swift run --disable-sandbox content-lint`: 成功（13状況・30記事、全件 `approved`）。
- `swift run --disable-sandbox content-lint --distribution`: 成功。
- `xcodegen generate`: 成功。
- `FourteenDayNote` generic iOS Simulator Debug / Release unsigned build: **`1.1.0 (7)` で成功**。
- iPhone 17 / iOS 26.5 SimulatorのXCUITest: **3件成功**（初回ホーム、地震記事直行、備え→買い物、ガイド復帰）。
- `swift test --disable-sandbox`: 66 tests / 12 suites 成功（V1永続ストアからV2への実移行と、残存PDF一時ディレクトリ削除のテストを含む）。
- `FourteenDayNote` generic iOS Simulator Release unsigned build: `1.0.0 (6)` で成功。
- `swift run --disable-sandbox content-lint`: 成功（13状況・30記事はすべて `approved`）。
- `swift run --disable-sandbox content-lint --distribution`: 成功。
- 生成したiOS app bundleで Bundle ID `jp.hazakura.FourteenDayNote`、`1.0.0 (6)`、Face ID文、暗号化フラグfalse、Privacy Manifest同梱を確認。
- Mac Releaseは過去に成功しているが、今回の申請対象外のため最終調整後は再検証していない。
- AppIcon source 11枚: 指定ピクセル寸法、RGB PNG、`hasAlpha: no` を確認。iOS / Mac Asset Catalogを含むRelease unsigned build成功。
- iPhone 17 / iOS 26.5 Simulator Debug unsigned + `simctl launch`: 成功（修正後に再検証）。過去の Release / iPad も成功済み。
- UI刷新後の `FourteenDayNote` iOS Simulator Release unsigned / `FourteenDayNoteMac` macOS Release unsigned: 成功。iPhone 17でガイド先頭・カード階層・タブ配色をスクリーンショット目視確認。
- コンテンツ正式化と注意事項追加後、65 tests / 12 suites、iPhone 17 Simulator Debug unsigned、`FourteenDayNoteMac` Debug unsigned が成功。

## Risks / Unknowns

- iPhone / iPad実機での機内モード30秒、VoiceOver、最大Dynamic Type、Reduce Motion、ダークモード、App Switcher秘匿、認証、PDF共有は未確認。
- 初見利用者5人の目的理解・10分準備フロー観察は未実施。
- v1.1 App Store画像は主要5点のみ更新済み。緊急カード、PDF、買い物リストは最終Release候補で再撮影が必要。
- Archive / Validate / Upload / App Store Connect入力・提出は未実施。
- 公開後フィードバックとコンテンツ鮮度の継続監視が必要。
- 失効 Development 証明書（lero003）が identity に残存する環境では使わない。
- 専門資格者による個別監修は未実施。編集確認済みという境界を維持する。
- Mac版の商品構成・Bundle ID・保存領域は、配布を実際に進めるときに再レビューする。

## Next Actions

1. v1.1をiPhone / iPad実機で `docs/MANUAL_SMOKE_CHECKLIST.md` に沿って確認する。
2. 初見利用者5人の観察テストを実施し、4人以上の基準を記録する。
3. 残るApp Store画像を最終Release候補で撮影し、Connect文面を本人が最終確認する。
4. `docs/RELEASE_SUBMISSION_CHECKLIST.md` に沿ってArchive / Validate / Upload / 提出する。Connectに後続ビルドがあればビルド番号を上げる。

## Avoid

- 公開済み Bundle ID を安易に変えない。
- `approved` を専門資格監修済み、またはあらゆる状況で正確と表現しない。
- 公開済みタグ `v1.0.0` を動かさない。修正は新コミットと必要なら次バージョンで行う。
- Upload や Team 固定をエージェントが独断しない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
