# Handoff

## Current State

- **2026-07-24: iOS App Store 審査通過・初回公開**（`1.0.0` / ビルド `6`、iPhone / iPad）。Git タグ `v1.0.0`。
- 公開範囲は **iPhone / iPadのみ**。Macターゲットはリポジトリに残すが、現行商品ページ・公開対象には含めない。
- フルMVP機能完了（オフラインガイド、探索、備蓄、緊急カード、公式リンク、PDF・印刷、Face ID 利用目的、暗号化 Infop、Privacy Manifest）。
- 同梱13状況・30記事はすべて `approved`。公的一次情報照合・編集確認済みで、専門資格監修や正確性保証ではない旨を常時表示。
- サポート / プライバシーは About と「その他」タブから開ける。本番URLは `https://hazakura.dev/14nichi-note/` 系。
- 申請用スクショと日本語メタデータは `docs/app-store-assets/`。変更履歴は `CHANGELOG.md`。

## Recent Changes

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

- 公開後フィードバックとコンテンツ鮮度の継続監視が必要。
- 失効 Development 証明書（lero003）が identity に残存する環境では使わない。
- 専門資格者による個別監修は未実施。編集確認済みという境界を維持する。
- Mac版の商品構成・Bundle ID・保存領域は、配布を実際に進めるときに再レビューする。

## Next Actions

1. 公開後の不具合・要望をホットフィックスと通常保守に分ける。
2. 記事・出典の定期的な再確認。更新時は `content-lint --distribution` を通す。
3. 次提出ではビルド番号を上げ、`docs/RELEASE_SUBMISSION_CHECKLIST.md` に従う。
4. Mac版は必要性が明確になるまで着手しない。

## Avoid

- 公開済み Bundle ID を安易に変えない。
- `approved` を専門資格監修済み、またはあらゆる状況で正確と表現しない。
- 公開済みタグ `v1.0.0` を動かさない。修正は新コミットと必要なら次バージョンで行う。
- Upload や Team 固定をエージェントが独断しない。
- ネットワーク、アカウント、解析、広告SDKを黙って追加しない。
