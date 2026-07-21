# Handoff

## Current State

- フルMVP機能完了。提出前のリポジトリ修正（Bundle ID 統一、Face ID 文、Mac Sandbox、暗号化 Infop、Privacy Manifest 同梱修正）まで完了。
- 緊急カードの非アクティブ時秘匿・復帰時再ロックと、PDF個人情報プレビューの認証境界を脅威モデルどおりに修正済み。
- 備蓄・買い物は入力中心から、人数・期間の選択、一般目安の確認、不足品目の選択、購入済みチェックだけの導線へ変更済み。
- iOS Simulator（iPhone 17 / iPad A16）ビルドと起動スモーク成功。
- アプリアイコンと画面内UIは、深い青緑・生成り・黄土・コーラルの共通デザインへ統一済み。
- 同梱13状況・30記事はすべて `approved`。公的一次情報照合・編集確認済みで、専門資格監修や正確性保証ではない旨を常時表示。
- Team 選択、実機、Archive Validate / Upload は本人操作。

## Recent Changes

- iOS/Mac の Bundle ID を `jp.hazakura.FourteenDayNote` に統一（同一商品ページ方針）。
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

## Decisions

- 同一「14日ノート」として iOS+Mac ユニバーサル購入を採用。`.mac` サフィックスは使わない。
- Team ID は `project.yml` に書かない。
- 一般公開候補は `content-lint --distribution` 必須。`approved` は編集確認状態であり専門資格監修とは表現しない。
- サポート/プライバシー URL は推測で固定しない。
- 食品は合計食数までとし、缶詰・乾パン等の個数配分は公的一律根拠がないため自動計算しない。

## Tests

- `swift test --disable-sandbox`: 65 tests / 12 suites 成功（V1永続ストアからV2への実移行テストを含む）。
- `FourteenDayNote` generic iOS Simulator Release unsigned build: 成功（新しい備蓄・買い物画面とSwiftData V2を含む）。
- `swift run --disable-sandbox content-lint`: 成功（13状況・30記事はすべて `approved`）。
- `swift run --disable-sandbox content-lint --distribution`: 成功。
- Mac Release unsigned: 成功（修正後に再検証）。
- iOS / Mac Release app bundleで共有 Bundle ID、`0.1.0 (2)`、暗号化フラグ、Privacy Manifest同梱を確認。
- AppIcon source 11枚: 指定ピクセル寸法、RGB PNG、`hasAlpha: no` を確認。iOS / Mac Asset Catalogを含むRelease unsigned build成功。
- iPhone 17 / iOS 26.5 Simulator Debug unsigned + `simctl launch`: 成功（修正後に再検証）。過去の Release / iPad も成功済み。
- UI刷新後の `FourteenDayNote` iOS Simulator Release unsigned / `FourteenDayNoteMac` macOS Release unsigned: 成功。iPhone 17でガイド先頭・カード階層・タブ配色をスクリーンショット目視確認。
- コンテンツ正式化と注意事項追加後、65 tests / 12 suites、iPhone 17 Simulator Debug unsigned、`FourteenDayNoteMac` Debug unsigned が成功。

## Risks / Unknowns

- 実機・Archive 署名は Team 未設定のため未実施。
- App Switcher の完全秘匿、復帰時再認証、共有/キャンセル後の一時PDF削除は実機手動スモークが必要。
- 失効 Development 証明書（lero003）が identity に残存。使わない。
- 一般公開用の公開 Web ページ・スクショが未着手。
- V1からV2への実データ移行と新しい備蓄→買い物導線は、既存データがある実機での手動スモークが必要。
- 専門資格者による個別監修と実機での全記事表示確認は未実施。編集確認済みという境界を維持する。

## Next Actions

1. Xcode で両ターゲットに Team を設定。
2. 実機スモーク（30秒、備蓄の人数・期間変更、不足選択、買い物の購入済みチェック、旧データ移行を含む）を記録。
3. Connect で iOS+macOS の1アプリを作成し、Archive → Validate → Upload。
4. 実機で注意事項・情報源・文字サイズ・行間を確認する。

## Avoid

- Bundle ID を初回 Upload 後に変える想定をしない。
- `approved` を専門資格監修済み、またはあらゆる状況で正確と表現しない。
- Upload や Team 固定をエージェントが独断しない。
