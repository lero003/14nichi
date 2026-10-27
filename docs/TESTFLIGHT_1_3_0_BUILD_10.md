# 1.3.0 (10) TestFlight配信記録

確認日: 2026-10-27 / 対象: iPhone・iPad / App ID: `6792703014`

ビルド9の実機テストで報告された記事詳細のスクロールを修正した追加ビルド。原因・計測・実機確認の限界は[`修正記録`](./ARTICLE_SCROLL_FIX_2026-10-27.md)、先行ビルド9の配信記録は[`TESTFLIGHT_1_3_0.md`](./TESTFLIGHT_1_3_0.md)を参照する。

## 識別と来歴

| 項目 | 確認値 |
|---|---|
| Bundle ID | `jp.hazakura.FourteenDayNote` |
| バージョン / ビルド | `1.3.0 (10)` |
| ソースコミット | `ec8f46b13bb6e8537ee6e07d6c32f09cd297a7ce`（origin/mainへpush済み） |
| Archive時の状態 | clean（sourceDirty=false） |
| SDK / 最低OS | iPhoneOS 27.1 / iOS 18.0 |
| デバイス | iPhone・iPad (`UIDeviceFamily=[1,2]`) |
| IPA SHA-256 | `a2314e1af3ef4483211ff43534d226777cdc1cbc992af8395607dffbf3c3094a` |
| 配布署名 SHA-1 | `4270F1F6D7848FB49772F668B74E2D4F8C54D749` |
| 配布プロファイルUUID | `3d3e3774-9763-4c2e-8389-eb919ee54a62` |
| プロファイル期限 | `2027-09-22 02:37:16 UTC` |

## ゲート

| ゲート | 結果 |
|---|---|
| 単体テスト | 85 tests / 14 suites成功 |
| UI回帰 | iPhone Air / iOS 27.0で10件、iPad可変幅3件成功。同じ修正コードのDebug・ビルド9で実行 |
| 最大Dynamic Type | Air / iOS 27.0、AX5でスクロール回帰2件成功 |
| content-lint --distribution | 13状況・30記事、全件approvedで成功（コンテンツ変更なし） |
| Archive / IPA export | FourteenDayNote / generic iOS / Release、1.3.0(10)で成功 |
| ローカル署名検証 | codesign --verify --strict成功、署名証明書とembedded profile一致 |
| 配布条件 | 署名済みentitlementsとprofileのapplication-id一致、get-task-allow=false、beta-reports-active=true、Privacy Manifest同梱 |
| Apple側Validate | Transporterで2026-10-27 20:41 JSTに検証済みを確認 |
| Upload | Transporterで2026-10-27 20:43 JSTにデリバリ済みを確認 |
| Apple処理 | 完了。Connectに1.3.0(10)・提出準備完了・有効期限90日を表示 |
| 内部グループ利用可能 | 既存 `test`（内部1名）へ自動追加。一覧の招待数1と、ビルド詳細のグループ(1)・test / 内部 / 1を確認 |
| App Store審査提出 | 未実施 |

ArchiveはAutomatic Signing。Teamは確認済み値をコマンドへ渡し、project.ymlへ固定していない。ExportOptionsはmethod=app-store-connect、destination=export、signingStyle=automatic、manageAppVersionAndBuildNumber=false。日本語名と実行属性を保持するためIPA展開はdittoを使用した。

既知の警告: ArchiveのAppIntentsメタデータ抽出スキップ、SimulatorのSDK build番号/debugger lookup診断、UIAccessibilityLoaderWebSharedの重複実装診断。署名情報の読み取りではcodesignの旧出力指定`:-`の非推奨警告も発生したが、検証は成功した。

[ビルド10の詳細](https://appstoreconnect.apple.com/teams/7f1841d3-e883-4079-8f26-58f3a4eb77fe/apps/6792703014/testflight/ios/7f363120-0810-42f0-80ea-f1fc834d0d56) / [既存内部グループ](https://appstoreconnect.apple.com/teams/7f1841d3-e883-4079-8f26-58f3a4eb77fe/apps/6792703014/testflight/groups/0b1ad850-867c-440f-8359-1f3863defe3a)

Air / iOS 27.2でのビルド9との比較、ジャンプ・文字サイズ・VoiceOver・幅変更を含む日本語のテスト内容を保存し、Connectの「保存済み」を確認した。実機のインストール・起動・受け入れ合格は未確認。ビルド9を期限切れにはしていない。App Store公開版は1.2のまま。

## 実機で確認すること

報告端末はiPhone Air / iOS 27.2。手元のSimulatorはiOS 27.0であり、実機27.2のFPSや症状解消は未確認。

1. ビルド10へ更新し、同じ記事の上下スクロールをビルド9と比較する。
2. 記事内ジャンプ後のスクロール、文字サイズ変更、VoiceOverを確認する。
3. 回転・画面幅変更で読書位置を保持することを確認する。

他の実機・Duo・公開前ゲートは`MANUAL_SMOKE_CHECKLIST.md`と`RELEASE_SUBMISSION_CHECKLIST.md`を引き続き使用する。
