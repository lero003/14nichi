# 内部 TestFlight 引き渡しメモ

最終更新: 2026-07-24
状態: **履歴**。初回 iOS 公開（`1.0.0` / ビルド `6`）は完了。再提出の手順正本は [`RELEASE_SUBMISSION_CHECKLIST.md`](./RELEASE_SUBMISSION_CHECKLIST.md)。

「コード完了」「Validate可能」「Upload済み」「App Store公開中」を混同しないこと。

## 1. アプリ識別情報（リポジトリ上の事実）

| 項目 | 値 |
|---|---|
| 表示名 | 14日ノート |
| Bundle ID（iOS） | `jp.hazakura.FourteenDayNote` |
| 商品構成 | **初回申請はiPhone / iPadのみ**。Macは今回含めない |
| バージョン | `1.0.0` |
| ビルド | `6` |
| カテゴリ（Info） | `public.app-category.lifestyle` |
| 対応 | iPhone / iPad（iOS 18+） |
| Face ID 利用目的 | 緊急カード表示時の本人確認（iOS Info） |
| 暗号化 Infop | `ITSAppUsesNonExemptEncryption = false`（OS標準のみ） |
| Macターゲット | 将来候補。Sandbox設定は残すが今回の申請対象外 |
| 署名スタイル | Automatic。**DEVELOPMENT_TEAM は未記入（推測禁止）** |

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
   - Bundle Identifier が `jp.hazakura.FourteenDayNote` であること。
4. 失効した Development 証明書（lero003@gmail.com）は使わない。
5. App Store Connectで **iOS** のアプリレコードを作成（iPhone / iPad）。macOSは追加しない。
6. Product → Archive（Any iOS Device）。
7. Organizer → **Validate** を先に実行。
8. Validate 成功後、明示的に **Upload**。

### iOS Platform / シミュレータ（2026-07-22 再検証）

iOS 26.5 Platform 導入後:

- `FourteenDayNote` iPhone 17 Simulator **Debug/Release ビルド成功**
- iPad (A16) Simulator ビルド成功
- `simctl launch jp.hazakura.FourteenDayNote` 起動スモーク成功
- 最終候補 `1.0.0 (6)` のgeneric iOS Simulator Releaseビルド成功
- 生成appのInfo.plistで Face ID 文・暗号化フラグ・iOSの確定済み Bundle ID・版番号を確認済み
- 生成appに `PrivacyInfo.xcprivacy` が同梱されることを確認済み

```sh
xcodegen generate
xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNote \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO build
```

## 3. Privacy Manifest / App Privacy の事実

同梱: `Sources/FourteenDayNoteApp/Resources/PrivacyInfo.xcprivacy`（ターゲット Resources に含まれること）

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

製品・サポート・プライバシー URL はアプリに設定済みで、2026-07-22に3ページともHTTP 200を確認した。公開前にユーザーが本文と問い合わせ先を最終目視し、App Store Connectへ登録する。

### 暗号化・輸出コンプライアンス

- 独自の暗号プロトコルは実装していない。
- HTTPS は OS の標準 URL オープンに依存。
- Infop: `ITSAppUsesNonExemptEncryption = false`（Connect の回答と一致させる）。
- 最終回答は **ユーザーが Connect 上で確認**。

## 4. TestFlight メタデータ案（要ユーザー確定）

| 項目 | 提案（未確定） |
|---|---|
| ベータAppの説明 | 災害時のオフライン行動確認用MVP。記事は公的一次情報との照合・編集確認済みですが、状況により不正確または古くなる可能性があります。個人情報は端末内のみ。 |
| テスト内容 | `docs/MANUAL_SMOKE_CHECKLIST.md` の A〜F |
| フィードバックメール | **ユーザーが指定**（推測しない） |
| 内部テスター | App Store Connect の Internal Testing グループへ本人が追加 |

## 5. コンテンツ確認状態

- 同梱30記事はすべて `approved`。公的一次情報との照合と編集確認を2026-07-20に実施。
- 専門資格者による個別監修や正確性保証ではない。全記事に情報が不正確または古くなる可能性と、最新の公式情報・現場の指示を優先する注意事項を表示する。
- App Store 一般公開候補では:

```sh
swift run --disable-sandbox content-lint --distribution
```

が成功することを必須とする。

## 6. エージェントが完了したこと / していないこと

### 完了

- フルMVP機能、脅威モデル、アイコン、Privacy Manifest
- Bundle ID 統一、Face ID 文、Mac Sandbox、暗号化 Infop
- Core テスト、Mac ビルド、**iOS Simulator ビルドと起動スモーク**
- 提出チェックリスト文書

### 未完了（本人操作）

- DEVELOPMENT_TEAM 選択
- 実機ビルド・30秒計測・VoiceOver 等の実機記録
- App Store Connect アプリ作成
- Release Archive の Validate / Upload
- 内部テスター設定、公開URL確認、用意済みスクショ・文章のConnect入力、実機でのコンテンツ表示確認

## 7. 推奨コマンド（ローカル）

```sh
swift test --disable-sandbox
swift run --disable-sandbox content-lint
xcodegen generate
xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNote \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO build
```
