# Handoff

## Current State

- フルMVP機能完了。提出前のリポジトリ修正（Bundle ID 統一、Face ID 文、Mac Sandbox、暗号化 Infop、Privacy Manifest 同梱修正）まで完了。
- 緊急カードの非アクティブ時秘匿・復帰時再ロックと、PDF個人情報プレビューの認証境界を脅威モデルどおりに修正済み。
- 備蓄・買い物は入力中心から、人数・期間の選択、一般目安の確認、不足品目の選択、購入済みチェックだけの導線へ変更済み。
- iOS Simulator（iPhone 17 / iPad A16）ビルドと起動スモーク成功。
- 同梱13状況・30記事はすべて `draft`。一般公開は監修後。
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

## Decisions

- 同一「14日ノート」として iOS+Mac ユニバーサル購入を採用。`.mac` サフィックスは使わない。
- Team ID は `project.yml` に書かない。
- 内部 TestFlight は draft フィクスチャ可。一般公開は `content-lint --distribution` 必須。
- サポート/プライバシー URL は推測で固定しない。
- 食品は合計食数までとし、缶詰・乾パン等の個数配分は公的一律根拠がないため自動計算しない。

## Tests

- `swift test --disable-sandbox`: 65 tests / 12 suites 成功（V1永続ストアからV2への実移行テストを含む）。
- `FourteenDayNote` generic iOS Simulator Release unsigned build: 成功（新しい備蓄・買い物画面とSwiftData V2を含む）。
- `swift run --disable-sandbox content-lint`: 成功（13状況・30記事は意図どおり `draft`）。
- Mac Release unsigned: 成功（修正後に再検証）。
- iOS / Mac Release app bundleで共有 Bundle ID、`0.1.0 (1)`、暗号化フラグ、Privacy Manifest同梱を確認。
- iPhone 17 / iOS 26.5 Simulator Debug unsigned + `simctl launch`: 成功（修正後に再検証）。過去の Release / iPad も成功済み。

## Risks / Unknowns

- 実機・Archive 署名は Team 未設定のため未実施。
- App Switcher の完全秘匿、復帰時再認証、共有/キャンセル後の一時PDF削除は実機手動スモークが必要。
- 失効 Development 証明書（lero003）が identity に残存。使わない。
- 一般公開用の公開 Web ページ・スクショ・記事監修が未着手。
- V1からV2への実データ移行と新しい備蓄→買い物導線は、既存データがある実機での手動スモークが必要。
- `content-lint --distribution` は30記事が `draft` のため意図どおり失敗する。内部TestFlight限定の候補であり、一般公開可能とは扱わない。

## Next Actions

1. Xcode で両ターゲットに Team を設定。
2. 実機スモーク（30秒、備蓄の人数・期間変更、不足選択、買い物の購入済みチェック、旧データ移行を含む）を記録。
3. Connect で iOS+macOS の1アプリを作成し、Archive → Validate → Upload。
4. 記事監修フェーズへ。

## Avoid

- Bundle ID を初回 Upload 後に変える想定をしない。
- 未監修記事を正式情報として扱わない。
- Upload や Team 固定をエージェントが独断しない。
