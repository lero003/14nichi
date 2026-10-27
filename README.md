# 14日ノート

災害、停電、断水、通信障害などで日常生活が一時的に機能しなくなったとき、個人や家庭が次の行動をオフラインで確認するためのiPhone・iPadアプリです。

**iOS App Store で公開中**（公開レコード `1.2`、選択ビルド `1.2.0 (8)` を2026-10-27にApp Store Connectで確認。公開日は未確認）。初回公開は `1.0.0 (6)`、2026-07-24審査通過です。オフライン閲覧、探索、備蓄、緊急カード、公式リンク集、PDF・印刷を提供します。Mac版はリポジトリに将来候補として残しますが、現行の公開商品には含めません。

`main` は次のiOS版 `1.3.0`（ビルド `10`）です。実機報告を受け、記事詳細のスクロール中の高さ補正と読書位置の保存を修正しました。Archive・Validate・Upload・Apple処理を完了し、既存内部グループ「test」（1名）から利用できます。App Store審査は未提出です。配信の来歴は [`ビルド10の記録`](./docs/TESTFLIGHT_1_3_0_BUILD_10.md)、修正の計測結果は [`スクロール修正記録`](./docs/ARTICLE_SCROLL_FIX_2026-10-27.md) を参照してください。既存のホーム・準備フローを引き継ぎ、ホームから緊急時の最優先記事へ直行し、平時は人数・不足品・任意の緊急カードを3項目で確認できます。買い物リストは「備え」の中へ統合しています。2026-10-27に防災ガイドの検索・記事内ジャンプ・読みやすさ導線を改善し、独立レビューで本文10記事の安全表現と出典を更新しました。画面幅の変更時に記事・読書位置を保持する改修も含みます。確認範囲とDuo固有の未検証事項は [`レビュー結果`](./docs/REVIEW_RESULTS_2026-10-27.md) を参照してください。公開済みの `v1.0.0` タグは変更しません。

企画の原本は [`14日note.md`](./14日note.md)、実装範囲は [`docs/PROJECT_FOUNDATION.md`](./docs/PROJECT_FOUNDATION.md)、既存機能スライスの判断履歴は [`docs/V1_1_PRODUCT_PLAN.md`](./docs/V1_1_PRODUCT_PLAN.md)、将来候補は [`docs/ROADMAP.md`](./docs/ROADMAP.md)、変更履歴は [`CHANGELOG.md`](./CHANGELOG.md) を参照してください。AIエージェントは [`AGENTS.md`](./AGENTS.md) を確認し、再提出や次ビルドの手順は [`docs/RELEASE_SUBMISSION_CHECKLIST.md`](./docs/RELEASE_SUBMISSION_CHECKLIST.md) を正本にしてください。申請画像と日本語文案は [`docs/app-store-assets/`](./docs/app-store-assets/) にあります。

## 現在の実装スライス

ホームは「いま困っている」と「平時に備える」を分け、地震・停電・断水・風水害・ケガ・避難の最優先記事へ1タップで進めます。同梱したMarkdown記事を状況別に一覧表示し、通信なしで全文検索・カテゴリ・行動時期・お気に入りを組み合わせて閲覧できます。記事内では「最初の5分」「やってはいけない」などの見出しへ移動でき、状況一覧・記事一覧・記事詳細のどこからでも読みやすさ設定を開けます。備蓄では人数と7日・14日だけを選ぶと、公的情報に基づく水・食料・携帯トイレの目安を表示し、その他の生活用品は不足チェックのみの買い物リストへ載せられます。選択状態はSwiftDataへ保存します。緊急カードは脅威モデルで定めた最小の個人情報だけを、備蓄とは分離した端末内ストアへ保存します。公式情報リンク集と、項目選択・明示同意付きのPDF・印刷を備えます。同梱30記事は公的一次情報との照合と編集確認を通過した `approved` です。

## 必要環境

- Xcode 26.6 以降（現在のローカル検証環境: Xcode 27.1）
- Swift 6.2 以降（現在のローカル検証環境: Swift 6.4）
- XcodeGen 2.x
- iOS / iPadOS 18.0 以降
- macOS 15.0 以降（将来候補のMacターゲットをビルドする場合）

外部パッケージへの依存はありません。

## 開発開始

```sh
git status
swift test --disable-sandbox
swift run content-lint
xcodegen generate
open FourteenDayNote.xcodeproj
```

`FourteenDayNote.xcodeproj` は XcodeGen の生成物で Git 管理しません。クローン後は必ず `xcodegen generate` してください。

`content-lint` は同梱manifestとMarkdownの整合を検証します。App Store 提出前の配布ゲートは次です。

```sh
swift run content-lint --distribution
```

生成した `FourteenDayNote.xcodeproj` はローカル生成物としてGit管理しません。v1.3の更新申請ではXcodeの `FourteenDayNote`（iPhone / iPad）を選択します。`FourteenDayNoteMac` は将来候補として残しますが、今回のArchive・Upload対象ではありません。SigningのTeamはXcodeで選択し、`project.yml` にTeam IDを推測で書かないでください。

## 安全上の境界

同梱記事は、情報源（発行者・確認日・利用形態・権利注記）、対象地域、最終確認日、確認主体、レビュー状態を揃えた製品コンテンツです。`approved` は公的一次情報との照合と編集確認を通過した意味であり、専門資格者による個別監修や、あらゆる状況での正確性を保証するものではありません。全記事で最新の公式情報と現場の指示を優先する注意事項を表示します。長い原文の転載は行わず、公的一次情報への参照と自前の要約を原則とします。詳細は [`docs/CONTENT_CONTRACT.md`](./docs/CONTENT_CONTRACT.md) を参照してください。個人情報の扱いと最小項目は [`docs/EMERGENCY_CARD_THREAT_MODEL.md`](./docs/EMERGENCY_CARD_THREAT_MODEL.md) を正とします。
