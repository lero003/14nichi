# Project Foundation

最終更新: 2026-07-20

## 現在地

フルMVPの機能実装（Slice 1〜4、公式リンク集、PDF・印刷）と、同梱コンテンツの公的一次情報照合・編集確認・`approved` 化まで完了しています。`approved` は専門資格者による個別監修や正確性保証を意味せず、全記事で不正確または古くなる可能性と公式情報優先を明示します。内部TestFlightはコードと文書の準備まで完了し、Appleアカウント側の署名・Archive・Uploadは利用者操作が残っています。

### いま動くもの

- 13状況 / 30記事の製品コンテンツ（すべて `approved`。公的一次情報照合・編集確認済み）
- manifest と front matter の検証付きローダー
- 優先度・期間ラベル付きの SwiftUI ブラウザ（iPhone / iPad / Mac）
- アプリ状態モデル（読み込み / 選択 / About / 読みやすさ）
- 読みやすさ設定（初期値は標準、文字サイズ5段階・広めの行間・太字・余白、端末内保存。端末側のより大きな文字設定を維持）
- モーション（選択・詳細切替の spring、Reduce Motion 対応）
- VoiceOverで移動できるMarkdown見出し、オフライン対応表示、About（製品ページリンク付き）、記事の短い注意＋詳細限界説明
- 情報源ブロック（権利注記・確認日・オンラインで開く公式リンク）
- AccentColor、App Icon、Privacy Manifest、Mac 既定ウィンドウサイズ、再試行可能な読み込みエラー
- `content-lint` によるコンテンツ検証と `--distribution` 配布ゲート
- 全記事を対象にしたオフライン全文検索（複数語AND検索、大文字小文字・全角半角を吸収）
- manifestの既存メタデータを使うカテゴリ・行動時期フィルタ（検索・お気に入り・状況選択と合成）
- お気に入り登録・絞り込み（記事IDだけを端末内保存）
- 合計人数と7日・14日の計画期間だけを使う備蓄計算
- 公的情報に基づく飲料水3L・食料3食・携帯トイレ5回分（いずれも1人1日）の一般的な目安を自動表示
- 生活用品・持ち出し品などチェックリスト品目（数量は自動計算せず不足チェックのみ）を同梱
- 利用者は家に足りない品目だけを選択し、選択状態と購入済み状態をSwiftDataへ端末内保存
- 足りない品目だけを表示する買い物リストと、1タップの購入済み操作
- 旧V1の詳細入力はV2へ軽量移行し、当時の不足・準備済み状態を新しい選択へ一度だけ変換
- 緊急カード（最小個人情報）の作成・閲覧・編集・削除、備蓄とは分離したSwiftDataストア
- 任意の端末認証ゲート、非アクティブ時の画面秘匿、全データ削除
- 公式情報リンク集（同梱JSON、httpsのみ、オンライン明示）
- PDF・印刷（項目選択、個人情報の明示同意、一時ファイル後片付け）
- Git 管理（`main`、XcodeGen 生成物は ignore）

### 2026-07-20 の検証状況

- `swift test --disable-sandbox`: 65 tests / 12 suites 成功
- `swift run --disable-sandbox content-lint`: OK（13 situations / 30 articles, all approved）
- `swift run --disable-sandbox content-lint --distribution`: OK
- `xcodegen generate`: 成功
- `FourteenDayNoteMac` Debug build（unsigned）: 成功
- `FourteenDayNote` iPhone 17 / iPad (A16) Simulator Debug・generic iOS Simulator Release: 成功
- Simulator 起動スモーク（`simctl launch`）: 成功
- About / 読みやすさは単一の sheet 状態で排他的に表示（コンパクト幅での右上 i クラッシュを修正）
- Release app bundle: 共有 Bundle ID、`0.1.0 (2)`、Face ID 利用目的、`ITSAppUsesNonExemptEncryption=false`、Privacy Manifest 同梱を確認
- 実機30秒計測 / VoiceOver実機 / Archive Validate: 未実施（手順は `docs/MANUAL_SMOKE_CHECKLIST.md` / `docs/RELEASE_SUBMISSION_CHECKLIST.md`）

## プロダクト判断

- 初期対象地域は日本。
- iPhone / iPad / MacをSwiftUIで提供する。
- 基本機能はログイン、広告、常時通信なしで利用できる。
- Markdownをコンテンツ原本とし、検索・表示用メタデータは `manifest.json` へ置く。
- 個人情報は `docs/EMERGENCY_CARD_THREAT_MODEL.md` の最小項目のみ。備蓄・お気に入りと保存境界を分離する。
- 災害・医療・食品衛生の文面は、アプリコードと別のレビュー対象にする。
- `approved` は編集レビューの配布状態とし、専門資格監修や状況ごとの正確性保証と混同しない。

## MVPの切り分け

### Slice 1: オフライン閲覧基盤（完了）

- 同梱manifestの検証と読み込み
- Markdown本文の読み込み
- 状況別一覧（優先度・期間で記事を並べ替え）
- 記事詳細（確認状態、上部の短い注意、要約、本文、詳細な限界説明、情報源ブロック）
- 情報源メタデータ（publisher / accessedAt / usage / rightsNote / 短文引用上限）
- iPhone / iPad / Mac共通UI
- `content-lint` による開発者向け検証
- Dynamic TypeとVoiceOverの基本対応（端末設定を縮小しない文字下限、独立した見出し要素。実機確認は残）

実装済みのmanifest検証: schema version、状況・記事IDの重複、未知の状況ID、Markdown相対パス、front matterのID・監修状態、`approved` の監修情報、出典の https / 実在日付 / usage と excerpt 整合、短文引用120文字上限。

完成条件: 機内モード相当の通信なし環境で起動し、ホームから対象記事の最初の行動まで30秒以内に到達できる。コード上の導線は用意済み。実機での30秒計測が残作業。

### Slice 2: 探索性（完了）

- 全文検索（実装済み）
- カテゴリ・行動時期フィルタ（実装済み）
- お気に入り（実装済み。記事IDのみ端末内保存）
- 初期コンテンツの拡充・公的一次情報照合・編集確認（完了）

### Slice 3: 備蓄（完了）

- 7日・14日の計算ルール（実装済み）
- 在庫と不足の表示（実装済み）
- チェックリストと期限表示（実装済み）
- SwiftData保存（V1スキーマと移行プラン、明示保存を実装済み）
- 不足品目の買い物リスト（実装済み）

数量の手入力は廃止。公的一次情報で数量まで確認できた3項目だけを「一般的な目安」として表示し、出典・確認日・オンライン参照導線を各品目に付ける。食料は合計食数までを計算し、缶詰・乾パンなどの内訳個数は家庭差が大きく公的な一律根拠がないため自動配分しない。

### Slice 4: 個人情報と出力（完了）

- 脅威モデルと最小データ: `docs/EMERGENCY_CARD_THREAT_MODEL.md`
- 緊急カードの作成・閲覧・編集・削除（実装済み）
- 備蓄と分離した永続ストア（実装済み）
- 任意のローカル認証、非アクティブ秘匿（実装済み）
- PDF・印刷の項目選択と明示同意（実装済み）
- 公式情報リンク集の独立導線（実装済み）

## 初期アーキテクチャ

```text
Markdown + manifest.json
OfficialLinks JSON
          |
          v
 FourteenDayCore
  - schema decoding
  - bundle loading
  - validation
  - stockpile / emergency stores (separate)
  - export / PDF
          |
          v
 SwiftUI app targets
  - iPhone / iPad
  - Mac
```

`FourteenDayCore` はSwift Packageとして単体テストできます。アプリプロジェクトは `project.yml` からXcodeGenで生成し、同じPackageをローカル依存として使います。

## まだ決めないこと

- iCloud同期
- 署名付きコンテンツ更新
- 完全オフライン地図
- 多人数共有
- Apple Watch
- 有料追加パック

## リスクと対策

| リスク | 最初の対策 |
|---|---|
| 誤った安全情報 | 直接出典・確認日・確認主体を記録し、限界を常時表示。更新時は再確認し、未完了なら `draft` / `reviewed` に戻す。`content-lint --distribution` |
| 著作権・転載リスク | 転載より `linkOnly` / `paraphrase`。`shortQuote` は120文字上限と権利注記必須 |
| 緊急時に読みにくい | 行動を先頭に置き、標準テキストスタイルとVoiceOverで確認 |
| manifestとMarkdownのずれ | ローダー検証とテストを追加し、content-lint |
| 個人情報漏えい | 最小データ、分離ストア、出力同意、ログ非記録、脅威モデル |
| 機能過多 | 30秒到達のガイド導線を維持し、拡張はスライス単位 |

## 提出前のリポジトリ方針（2026-07-20 確定）

- iOS / Mac は **同一 Bundle ID** `jp.hazakura.FourteenDayNote`（同一商品・ユニバーサル購入）。
- Mac App Sandbox 必須。PDF のユーザー任意パス直接保存は未実装のため file 権限は付けない。
- Face ID 利用目的文と非免除暗号なしフラグを Infop に設定。
- 提出手順の正本: [`RELEASE_SUBMISSION_CHECKLIST.md`](./RELEASE_SUBMISSION_CHECKLIST.md)

## 次の着手候補

1. Xcode で Team を選択し、実機ビルドと `docs/MANUAL_SMOKE_CHECKLIST.md` を記録する。
2. `docs/TESTFLIGHT_HANDOFF.md` / `docs/RELEASE_SUBMISSION_CHECKLIST.md` に従い Archive → Validate → 内部TestFlight Upload。
3. App Store 一般公開条件の充足（プライバシーポリシーURL、実機a11y、商品ページ素材）。
