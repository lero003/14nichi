# 1.3.0 (9) TestFlight配信記録

確認日: 2026-10-27 / 対象: iPhone・iPad / App ID: `6792703014`

## 識別と来歴

| 項目 | 確認値 |
|---|---|
| Bundle ID | `jp.hazakura.FourteenDayNote` |
| バージョン / ビルド | `1.3.0 (9)` |
| ソースコミット | `58d63e09335fc46e9c3e3cdc599640f20a947dd4`（origin/mainへpush済み） |
| Archive時の状態 | clean（sourceDirty=false） |
| SDK / 最低OS | iPhoneOS 27.1 / iOS 18.0 |
| デバイス | iPhone・iPad (`UIDeviceFamily=[1,2]`) |
| IPA SHA-256 | `9c17bf56c04dc640cf1bfe7b58eecbc16ba0e891eacc64602ef3156a3a4d74e2` |
| 配布署名 SHA-1 | `4270F1F6D7848FB49772F668B74E2D4F8C54D749` |
| 配布プロファイルUUID | `3d3e3774-9763-4c2e-8389-eb919ee54a62` |
| プロファイル期限 | `2027-09-22 02:37:16 UTC` |

現在のApp Store公開レコードは `1.2`、選択ビルド `1.2.0 (8)` と2026-10-27にConnectで確認した。公開日は未確認。次の番号9を選び、マーケティング版は本人指定に従い1.3.0とした。

## ゲート

| ゲート | 結果 |
|---|---|
| 単体テスト | 85 tests / 14 suites成功。版番号以外のアプリコードは同じ独立レビュー済み実装 |
| UI回帰 | iPhone 8件・iPad可変幅3件成功（実行時1.2.0(7)、同じアプリコード。9での実機合格ではない） |
| content-lint --distribution | 13状況・30記事、全件approvedで成功 |
| Archive | 1.3.0(9) / FourteenDayNote / generic iOS / Release成功 |
| IPA export | App Store Connect用export成功 |
| ローカル署名検証 | codesign --verify --strict成功、署名証明書とembedded profile一致 |
| 配布条件 | get-task-allow=false、beta-reports-active=true、Bundle ID一致、Privacy Manifest同梱 |
| Apple側Validate | Transporterで2026-10-27 20:03 JSTに検証済みを確認 |
| Upload | Transporterで2026-10-27 20:06 JSTにデリバリ済みを確認 |
| Apple処理 | 完了。Connectに1.3.0(9)・提出準備完了・有効期限90日を表示 |
| 内部グループ利用可能 | 既存 `test`（内部1名）へ自動追加。ビルド詳細のグループ(1)・一覧招待数1・グループのビルド数2を確認 |
| App Store審査提出 | 未実施 |

署名はAutomaticで、既存の配布証明書を含むXcode管理プロファイルを更新・取得して整合させた。project.ymlへTeamを固定せず、ArchiveコマンドのDEVELOPMENT_TEAMへ確定値を渡した。版番号の自動管理を無効にし、export後のIPAも1.3.0(9)と確認した。

Archive時の既知警告はAppIntentsメタデータ抽出スキップ。検証用展開にはmacOSのdittoを使用した（日本語ファイル名・実行属性を保持）。

## 実行した配布コマンド

- `xcodegen generate`
- `xcodebuild -project FourteenDayNote.xcodeproj -scheme FourteenDayNote -configuration Release -destination 'generic/platform=iOS' -archivePath <repo外のpath> CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=<確認済みTeam> archive`
- `xcodebuild -exportArchive -archivePath <archive> -exportOptionsPlist <options> -exportPath <repo外のpath>`
- ExportOptions: method=app-store-connect、destination=export、signingStyle=automatic、manageAppVersionAndBuildNumber=false。
- 同梱プロファイルと署名の公開証明書を照合し、IPAの版番号・SDK・対象デバイス・暗号化フラグを確認。

既存内部グループは `test`（1名）。設定は「Xcodeビルドを自動配信」。1.3.0(9)のグループ割当を確認し、日本語のテスト内容を保存済み。

[ビルド詳細](https://appstoreconnect.apple.com/teams/7f1841d3-e883-4079-8f26-58f3a4eb77fe/apps/6792703014/testflight/ios/deefeb97-6052-4c33-a30b-22608f267d71) / [内部グループ](https://appstoreconnect.apple.com/teams/7f1841d3-e883-4079-8f26-58f3a4eb77fe/apps/6792703014/testflight/groups/0b1ad850-867c-440f-8359-1f3863defe3a)

Connectの内部テスター欄には「インストール済み 1.3.0 (9)」も表示された。ただし端末を直接操作したインストール確認・起動スモーク・受け入れテストは実施していない。App Store公開版は1.2のまま。

## TestFlightで確認する項目

1. 機内モードで起動し、最初の行動へ30秒以内に到達する。
2. 検索、避難ショートカット、記事内ジャンプ、読みやすさ設定。
3. VoiceOverでジャンプ先の見出しから本文へ進む。最大文字・Reduce Motion・iPadキーボードも確認。
4. Duoの開閉・回転・折った状態・Split Viewで、記事/検索/読書位置と操作領域を確認。
5. 備え・買い物・緊急カード認証/秘匿・PDF共有の既存実機スモーク。

Duo固有のpose・非対称セーフエリア、実機アクセシビリティ、App Switcher秘匿等は未確認。Simulatorの可変幅成功、Appleの処理完了、利用者の受け入れ確認は別の事実として扱う。

同梱記事は公的一次情報との照合・編集確認済みだが、専門資格者による個別監修や正確性保証ではない。更新・出典の確認範囲は `REVIEW_RESULTS_2026-10-27.md` を参照する。
