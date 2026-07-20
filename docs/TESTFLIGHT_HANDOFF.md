# 内部 TestFlight 引き渡しメモ

最終更新: 2026-07-20  
状態: **コードと文書は準備済み。Archive Validate / Upload は Apple アカウント操作が必要。**

「コード完了」「Validate可能」「Upload済み」「App Store公開可能」を混同しないこと。

## 1. アプリ識別情報（リポジトリ上の事実）

| 項目 | 値 |
|---|---|
| 表示名 | 14日ノート |
| iOS Bundle ID | `jp.hazakura.FourteenDayNote` |
| Mac Bundle ID | `jp.hazakura.FourteenDayNote.mac` |
| バージョン | `0.1.0` |
| ビルド | `1` |
| カテゴリ（Info） | `public.app-category.lifestyle` |
| 対応 | iPhone / iPad（iOS 18+）、Mac（macOS 15+） |
| 署名スタイル | Automatic（`project.yml`）。**DEVELOPMENT_TEAM は未記入（推測禁止）** |

## 2. この Mac で読み取れた署名関連（要本人確認）

`security find-identity -v -p codesigning` の結果（2026-07-20）:

| 状態 | Identity |
|---|---|
| **失効** | Apple Development: lero003@gmail.com (A96KNANR4F) — `CSSMERR_TP_CERT_REVOKED` |
| 有効 | Apple Development: Keitaro Matsukura (A96KNANR4F) |
| 有効 | Apple Distribution: Keitaro Matsukura (8BNUB2R9C8) |
| 有効 | Developer ID Application: Keitaro Matsukura (8BNUB2R9C8) |

Team ID らしき値: **8BNUB2R9C8**（証明書の表示から読み取り。リポジトリには書き込んでいない）。

### ユーザーが Xcode で行う操作

1. Xcode → Settings → Accounts で Apple ID を追加/更新する。
2. `xcodegen generate` 後に `FourteenDayNote.xcodeproj` を開く。
3. ターゲット **FourteenDayNote** → Signing & Capabilities:
   - Team を選択（例: Keitaro Matsukura / 8BNUB2R9C8 を本人確認のうえ）。
   - Automatically manage signing をオン。
   - Bundle Identifier が `jp.hazakura.FourteenDayNote` のままか確認。
4. 失効した Development 証明書（lero003@gmail.com）は使わない。必要なら Apple Developer で失効証明書を整理し、有効な Development を残す。
5. App Store Connect で同じ Bundle ID の App を作成（未作成なら）。
6. Product → Archive（Any iOS Device / Generic iOS Device）。
7. Organizer → Distribute App → App Store Connect → **Validate** を先に実行。
8. Validate 成功後、明示的に Upload を実行（エージェントは資格情報が揃うまで Upload しない）。

### iOS Platform / シミュレータ

この環境では `xcodebuild -showsdks` に iOS 26.5 が出ても、destination は次のエラーになる場合がある:

> iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.

**ユーザー操作**: Xcode → Settings → Components で **iOS 26.5** プラットフォームをダウンロード。完了後:

```sh
xcodegen generate
xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNote \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO build
```

（シミュレータ名は `xcodebuild -scheme FourteenDayNote -showdestinations` で確認。）

## 3. Privacy Manifest / App Privacy の事実

同梱: `Sources/FourteenDayNoteApp/Resources/PrivacyInfo.xcprivacy`

| 項目 | 実装上の事実 |
|---|---|
| トラッキング | しない（`NSPrivacyTracking` = false） |
| 収集データタイプ宣言 | 空（解析・広告 SDK なし） |
| Required Reason API | UserDefaults のみ（`CA92.1` = 同一アプリ内設定） |
| ネットワーク | 利用者が公式 https リンクを開く操作のみ |
| アカウント | なし |
| 位置情報 | なし |
| 緊急カード | 端末内のみ。iCloud 同期なし |

### App Store Connect の App Privacy 回答の材料（回答自体はユーザーが入力）

- データを収集して開発者サーバへ送るか: **送らない**（現状コード）。
- 連絡先・健康情報をクラウド収集するか: **しない**。端末内の利用者入力のみ。
- トラッキングするか: **しない**。

プライバシーポリシー URL はリポジトリに未設定。公開前にユーザーが用意して App Store Connect に登録する。内部TestFlightのみでもポリシーが必要な場合は Connect の指示に従う。

### 暗号化・輸出コンプライアンス

- 独自の暗号プロトコルは実装していない。
- HTTPS は OS の標準 URL オープンに依存。
- App Store Connect の質問（標準暗号化のみか等）は **ユーザーが回答**。値を推測して rep に固定しない。

## 4. TestFlight メタデータ案（要ユーザー確定）

| 項目 | 提案（未確定） |
|---|---|
| ベータAppの説明 | 災害時のオフライン行動確認用MVP。記事は未監修の制作フィクスチャ。個人情報は端末内のみ。 |
| テスト内容 | `docs/MANUAL_SMOKE_CHECKLIST.md` の A〜F |
| フィードバックメール | **ユーザーが指定**（推測しない） |
| 内部テスター | App Store Connect の Internal Testing グループへ本人が追加 |

## 5. コンテンツ監修状態

- 同梱 5 記事はすべて `draft`。
- 内部TestFlightでは未監修バナーを維持したまま配布してよい（フィクスチャと明示）。
- App Store 一般公開前は:

```sh
swift run --disable-sandbox content-lint --distribution
```

が成功するまで（全記事 `approved` + 出典・確認者等）製品コンテンツにしない。

## 6. エージェントが完了したこと / していないこと

### 完了

- Slice 4: 脅威モデル、緊急カード、分離保存、認証オプション、秘匿、削除
- 公式リンク集、PDF・印刷（項目選択・同意・一時ファイル）
- Core テスト拡充、Mac 未署名ビルド
- App Icon、Privacy Manifest、手動スモーク、本引き渡し
- 配布ゲート `content-lint --distribution`

### 未完了（環境・本人操作）

- iOS Platform 導入、iOS Simulator / 実機ビルド
- 実機30秒計測と VoiceOver 等の実機記録
- DEVELOPMENT_TEAM 設定、証明書・Profile の自動生成確認
- Release Archive の作成・Validate・Upload
- App Store Connect のアプリ作成、プライバシー回答、テスター招待

## 7. 推奨コマンド（ローカル）

```sh
swift test --disable-sandbox
swift run --disable-sandbox content-lint
# App Store 提出前のみ:
# swift run --disable-sandbox content-lint --distribution
xcodegen generate
xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNoteMac \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```
