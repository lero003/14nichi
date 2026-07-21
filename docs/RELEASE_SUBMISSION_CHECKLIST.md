# 提出・公開チェックリスト（内部用）

最終更新: 2026-07-22
対象: 内部 TestFlight → 一般公開までの実務手順
公開範囲: **リポジトリ内の開発ドキュメント**。サポートURLやプライバシー本文の本番公開ページではない。機密（証明書パスワード、Apple ID、税務情報）は書かない。

「コード完了」「Validate 成功」「Upload 済み」「App Store 公開可能」を混同しない。

関連:

- 脅威モデル: [`EMERGENCY_CARD_THREAT_MODEL.md`](./EMERGENCY_CARD_THREAT_MODEL.md)
- 手動スモーク: [`MANUAL_SMOKE_CHECKLIST.md`](./MANUAL_SMOKE_CHECKLIST.md)
- TestFlight 引き渡し: [`TESTFLIGHT_HANDOFF.md`](./TESTFLIGHT_HANDOFF.md)
- 実行仕様（完了済み）: [`FULL_MVP_COMPLETION_BRIEF.md`](./FULL_MVP_COMPLETION_BRIEF.md)

---

## 0. 現状サマリ（実装リポジトリ）

| 優先 | やること | 現状（リポジトリ） |
|---|---|---|
| 最優先 | 初回申請プラットフォーム | **iPhone / iPadのみ**。macOSは追加しない |
| 将来候補 | Macターゲット | リポジトリには残すが、今回の申請対象外 |
| 最優先 | Face ID 利用目的文 | **追加済み** `NSFaceIDUsageDescription` |
| TestFlight 前 | Team、実機、Archive、Validate、Upload | **本人操作** |
| 一般公開前 | 記事 `approved` 化 | **完了**（30記事、公的一次情報照合・編集確認） |
| 一般公開前 | 製品 / プライバシー / サポート公開ページ | 3 URLとも2026-07-22にHTTP 200を確認。本文・問い合わせ先は本人が最終目視 |
| 一般公開前 | スクリーンショット・説明文 | `docs/app-store-assets/` に用意済み。Connect未入力 |

今回のiOS公開候補: マーケティング `1.0.0` / ビルド `6`
署名スタイル: Automatic。`DEVELOPMENT_TEAM` は `project.yml` に書かない。

---

## 1. 商品構成の方針（確定）

### 採用: 初回申請はiPhone / iPadのみ

| プラットフォーム | Bundle ID |
|---|---|
| iOS / iPadOS | `jp.hazakura.FourteenDayNote` |
| macOS | **今回のApp Store Connectレコードへ追加しない** |

Macターゲットは将来候補としてコードに残す。今回のArchive、Validate、Upload、商品ページ素材、審査はiOSターゲットだけを対象にする。

将来Mac版を配布するときは、当時の実装・署名・保存領域・商品構成を改めてレビューする。今回の判断だけでユニバーサル購入を予約または確約しない。

---

## 2. リポジトリで完了すべき提出前修正

### 2-1. Face ID 利用目的（iOS）— 実装済み

```yaml
INFOPLIST_KEY_NSFaceIDUsageDescription: 緊急カードを表示する際の本人確認に使用します。
```

緊急カードの任意ロックが `LocalAuthentication`（Face ID / Touch ID / パスコード）を使うため必須。

### 2-2. Mac App Sandbox — 実装済み（将来候補・今回対象外）

- ファイル: `Sources/FourteenDayNoteApp/FourteenDayNoteMac.entitlements`
- `com.apple.security.app-sandbox = true`
- 現状 PDF は一時ディレクトリ + 印刷/プレビュー導線のため、`files.user-selected.read-write` は**まだ付けない**
- 公式リンクは OS に URL を渡すだけ。アプリ自身の `URLSession` 通信を追加したら Outgoing Network を再検討
- Capability は Xcode 画面だけでなく **`project.yml` を正本**にする（`xcodegen generate` で消えないようにする）

### 2-3. 暗号化 Infopリスト — 設定済み（回答と一致させる）

実装事実: 独自暗号プロトコルなし。HTTPS は OS のリンクオープンのみ。

```yaml
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: false
```

App Store Connect の輸出コンプライアンス質問でも同じ前提で回答する。回答方針が変わったら Infop を直す。

### 2-4. 検証コマンド

```sh
git status
swift test --disable-sandbox
swift run --disable-sandbox content-lint
xcodegen generate
xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build
```

一般公開候補のみ:

```sh
swift run --disable-sandbox content-lint --distribution
```

全30記事が `approved` のため、distribution の成功を提出候補ごとに確認する。

---

## 3. Apple アカウント・署名（本人）

### 3-1. アカウント

Xcode → Settings → Accounts:

- Developer Program 有効
- Team 表示
- App Store Connect ログイン可
- 最新契約同意
- 有料にするなら税務・銀行情報

### 3-2. 証明書の用途

| 種類 | 用途 |
|---|---|
| Apple Development | 実機デバッグ |
| Apple Distribution | App Store 提出 |
| Developer ID Application | **Mac App Store 外**配布（今回の提出経路では主に使わない） |

失効済みの古い Development は使わない。Automatic Signing を基本とする。

### 3-3. Xcode での Team

```sh
xcodegen generate
open FourteenDayNote.xcodeproj
```

今回の対象ターゲット **FourteenDayNote**:

- Automatically manage signing: ON
- Team: 自分の Team
- Bundle ID: `jp.hazakura.FourteenDayNote`

Team ID を `project.yml` に推測で固定しない。

---

## 4. 品質確認

### 自動

上記 §2-4。

### 手動（実機・シミュレータ）

[`MANUAL_SMOKE_CHECKLIST.md`](./MANUAL_SMOKE_CHECKLIST.md) の A〜H。最低限:

- オフライン起動と30秒到達
- 検索・フィルタ・お気に入り
- 備蓄保存と再起動復元
- 緊急カード・認証・App Switcher 秘匿
- PDF 共有/印刷
- VoiceOver / 最大 Dynamic Type / ダーク / iPad / 横向き

---

## 5. App Store Connect でアプリレコード作成（本人）

```text
マイApp → ＋ → 新規App
```

| 項目 | 値の例 |
|---|---|
| プラットフォーム | **iOS**（iPhone / iPad） |
| 名前 | 14日ノート |
| プライマリ言語 | 日本語 |
| Bundle ID | `jp.hazakura.FourteenDayNote` |
| SKU | 例: `14NICHI-001`（一意なら任意） |
| ユーザーアクセス | フルアクセス |

**ビルド Upload 前にレコードが必要。**

---

## 6. Archive · Validate · Upload（本人）

前提: Xcode 26+ / 対応SDK（リポジトリ前提はXcode 26.6）。最低対応OSはiOS 18。

### iOS

1. Scheme `FourteenDayNote`
2. Destination `Any iOS Device`
3. Product → Archive
4. Validate App
5. Distribute → App Store Connect → Upload

Validate 成功 ≠ Upload 成功。再 Upload 時は **Build 番号を増やす**（`CURRENT_PROJECT_VERSION`）。
既存の内部 TestFlight `0.1.0 (5)` より新しい提出物として、今回の一般公開候補は `1.0.0 (6)`。同じバージョンを再 Upload する場合も Build 番号をさらに増やす。

---

## 7. 内部 TestFlight（本人）

```text
TestFlight → Internal Testing → グループ → 自分を追加 → ビルド追加
```

ベータ説明に含めること:

- 災害時のオフライン行動確認用 MVP
- 記事は公的一次情報との照合・編集確認済みだが、状況や更新により不正確または古くなる可能性がある
- 緊急カードは端末内のみ
- アカウント・広告・解析なし
- PDF/共有には利用者が選んだ個人情報が含まれる場合がある

フィードバックメールは推測せず本人が設定。

---

## 8. 一般公開の追加ブロッカー

### 必須公開 URL（本人が用意・公開状態）

例（実際のホストは任意。404 不可）:

- サポート: 問い合わせ先が分かるページ
- プライバシーポリシー: データ収集の有無を説明（収集しなくても必須）

リポジトリに本番 URL を決め打ちしない。用意できたら Connect に入力する。

### App Privacy（実装事実に基づく回答候補）

| 質問 | 候補 |
|---|---|
| データを収集しますか | いいえ（開発者サーバへ送らない） |
| トラッキング | いいえ |
| 広告・位置・アカウント | 収集しない |
| 連絡先・健康情報 | 端末内のみ。開発者へ送信しない |

Privacy Manifest 同梱済み（トラッキングなし、UserDefaults CA92.1 のみ）。

### 商品ページ

- 名前 / サブタイトル / 説明 / キーワード
- スクリーンショット（`docs/app-store-assets/` のiPhone 6.9インチ・iPad 13インチJPEG）
- Copyright / 年齢制限 / カテゴリ
- App Review 連絡先 / Review Notes

画面候補: 状況選択、オフライン記事、備蓄、買い物、緊急カード、PDF。

### 年齢制限・審査

- 年齢質問への回答必須
- **プレースホルダー / 未完成コンテンツは審査で不可**
- 一般公開前: 全記事 `approved` + `content-lint --distribution` 成功

---

## 9. 最短手順（現実的な順番）

| # | 作業 | 担当 |
|---|---|---|
| 1 | Bundle ID 統一 | **済** |
| 2 | Face ID 文 | **済** |
| 3 | Mac版を初回申請から除外 | **済** |
| 4 | `xcodegen generate` + 自動テスト/配布lint/iOS Releaseビルド | **済**（2026-07-22、`1.0.0 (6)`） |
| 5 | Xcode で Team 選択 | **本人** |
| 6 | iPhone 実機ビルド | **本人**（実機接続） |
| 7 | 手動スモーク A〜F 記録 | **本人**（実機中心） |
| 8 | App Store Connect アプリレコード | **本人** |
| 9 | iOS Archive → Validate → Upload | **本人** |
| 10 | 内部 TestFlight | **本人** |
| 11 | 記事の編集確認・`approved` | **済** |
| 12 | 製品/サポート/プライバシーURLの本文・問い合わせ先を最終目視 | **本人**（HTTP 200は確認済み） |
| 13 | 用意済みスクショ・説明文・年齢・Review入力 | **本人** |

---

## 10. エージェントがやってよいこと / やってはいけないこと

### よい

- `project.yml`・entitlements・Info キーの修正
- テスト、content-lint、未署名/シミュレータビルド
- 内部ドキュメント更新、コミット、push
- 署名 identity の**読み取り**と文書化

### いけない（本人操作）

- Team の推測固定、証明書の失効・再発行の独断
- App Store Connect への Upload（資格情報と明示権限なし）
- 一般公開提出、外部テスター招待
- フィードバックメール・プライバシー URL のでっち上げ
- 出典や安全上の確認をせずに記事を `approved` 化
