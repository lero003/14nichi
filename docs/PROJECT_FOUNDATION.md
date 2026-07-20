# Project Foundation

最終更新: 2026-07-20

## 現在地

Slice 1「オフライン閲覧基盤」を完了し、Slice 2の全文検索・お気に入りまで進んでいます。状況選択 → 優先度付き記事一覧 → 詳細表示に加え、全記事の端末内検索とお気に入り絞り込みを、同梱の未監修フィクスチャで確認できます。製品コンテンツの監修や備蓄機能はまだです。

### いま動くもの

- 4状況 / 5記事の同梱フィクスチャ（すべて `draft`）
- manifest と front matter の検証付きローダー
- 優先度・期間ラベル付きの SwiftUI ブラウザ（iPhone / iPad / Mac）
- アプリ状態モデル（読み込み / 選択 / About / 読みやすさ）
- 読みやすさ設定（文字サイズ4段階・太字・余白、端末内保存。端末側のより大きな文字設定を維持）
- モーション（選択・詳細切替の spring、Reduce Motion 対応）
- VoiceOverで移動できるMarkdown見出し、オフライン対応表示、About、未監修バナー
- 情報源ブロック（権利注記・確認日・オンラインで開く公式リンク）
- AccentColor、Mac 既定ウィンドウサイズ、再試行可能な読み込みエラー
- `content-lint` によるコンテンツ検証コマンド
- 全記事を対象にしたオフライン全文検索（複数語AND検索、大文字小文字・全角半角を吸収）
- お気に入り登録・絞り込み（記事IDだけを端末内保存）
- Git 管理（`main`、XcodeGen 生成物は ignore）

### 2026-07-20 の検証状況

- `swift test --disable-sandbox`: 24 tests / 4 suites 成功
- `swift run --disable-sandbox content-lint`: OK（4 situations / 5 articles）
- `xcodegen generate`: 成功
- `FourteenDayNoteMac` Debug build（unsigned）: 成功
- `FourteenDayNote` iOS build: ローカルに iOS 26.5 Platform 未導入のため未実施（`Xcode > Settings > Components` で導入が必要）
- iOSシミュレータ起動: 同上のため未実施

## プロダクト判断

- 初期対象地域は日本。
- iPhone / iPad / MacをSwiftUIで提供する。
- 基本機能はログイン、広告、常時通信なしで利用できる。
- Markdownをコンテンツ原本とし、検索・表示用メタデータは `manifest.json` へ置く。
- 個人情報を扱う機能は、閲覧基盤とは別フェーズで脅威モデルと保存方針を決めてから実装する。
- 災害・医療・食品衛生の文面は、アプリコードと別のレビュー対象にする。
- フルMVPの機能を先に完成させ、その後にTestFlight準備、記事拡充・監修の順で進める。

## MVPの切り分け

### Slice 1: オフライン閲覧基盤（現在・骨格完了）

- 同梱manifestの検証と読み込み
- Markdown本文の読み込み
- 状況別一覧（優先度・期間で記事を並べ替え）
- 記事詳細（未監修バナー、要約、本文、情報源ブロック）
- 情報源メタデータ（publisher / accessedAt / usage / rightsNote / 短文引用上限）
- iPhone / iPad / Mac共通UI
- `content-lint` による開発者向け検証
- Dynamic TypeとVoiceOverの基本対応（端末設定を縮小しない文字下限、独立した見出し要素。実機確認は残）

実装済みのmanifest検証: schema version、状況・記事IDの重複、未知の状況ID、Markdown相対パス、front matterのID・監修状態、`approved` の監修情報、出典の https / 実在日付 / usage と excerpt 整合、短文引用120文字上限。

完成条件: 機内モード相当の通信なし環境で起動し、ホームから対象記事の最初の行動まで30秒以内に到達できる。コード上の導線は用意済み。実機での30秒計測が残作業。

### Slice 2: 探索性（進行中）

- 全文検索（実装済み）
- カテゴリ・時間帯フィルタ
- お気に入り（実装済み。記事IDのみ端末内保存）
- 初期コンテンツの拡充・監修フロー（フルMVP機能完成後）

### Slice 3: 備蓄

- 7日・14日の計算ルール
- 在庫と不足の表示
- 期限と買い物リスト
- SwiftData保存

### Slice 4: 個人情報と出力

- 緊急カードのデータ最小化
- 端末内保護とロック時の挙動
- エクスポート時の明示的な同意
- PDF・印刷

## 初期アーキテクチャ

```text
Markdown + manifest.json
          |
          v
 FourteenDayCore
  - schema decoding
  - bundle loading
  - validation
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

これらは最初の閲覧基盤の実機評価を終えるまで、設計や依存を先取りしません。

## リスクと対策

| リスク | 最初の対策 |
|---|---|
| 誤った安全情報 | `draft` を既定にし、出典・確認日・確認者が揃うまで公開対象外 |
| 著作権・転載リスク | 転載より `linkOnly` / `paraphrase`。`shortQuote` は120文字上限と権利注記必須 |
| 緊急時に読みにくい | 行動を先頭に置き、標準テキストスタイルとVoiceOverで確認 |
| manifestとMarkdownのずれ | ローダー検証とテストを追加し、後続で生成・lintツール化 |
| 個人情報漏えい | 閲覧基盤から分離し、保存・出力・同期を別レビュー |
| 機能過多 | Slice 1の30秒到達条件を満たすまで備蓄・PDFを実装しない |

## 次の着手候補

1. 7日・14日の備蓄計算を、入力・計算・不足表示まで一つの縦スライスで実装する。
2. 備蓄チェックリストの端末内保存と期限表示を追加する。
3. カテゴリ・時間帯フィルタを追加してSlice 2を閉じる。
4. 個人情報スライス前に、緊急カードの脅威モデルと端末内保護方針を確定する。
5. フルMVP機能完成後に、iPhone実機テストとTestFlight準備へ進む。
