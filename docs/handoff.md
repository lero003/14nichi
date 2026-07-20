# Handoff

## Current State

- フルMVP機能は完了。Slice 1〜3に加え、Slice 4（緊急カード・保護・削除）、公式リンク集、PDF・印刷まで実装済み。
- 同梱記事は4状況 / 5件の `draft` のまま（拡充・監修は未着手）。
- 内部TestFlight向けのアイコン、Privacy Manifest、手動スモーク、引き渡し文書を追加済み。
- Apple 側の Team 選択、iOS Platform 導入、Archive Validate / Upload は未実施。

## Recent Changes

- `docs/EMERGENCY_CARD_THREAT_MODEL.md` で最小データと保護方針を確定したうえで個人情報を実装した。
- 緊急カードを備蓄と分離した SwiftData ストアへ保存。任意の端末認証、非アクティブ秘匿、全削除を実装。
- 公式リンク集を同梱 JSON で管理し、「その他」タブから独立導線にした。
- PDF は項目選択と個人情報の明示同意後のみ生成。一時ファイル後片付けをテストした。
- `content-lint --distribution` で App Store 提出時の approved 以外混入を拒否する。
- App Icon と PrivacyInfo.xcprivacy（UserDefaults CA92.1）を追加。

## Decisions

- アプリ内文字サイズは端末設定を上書きする値ではなく、読みやすさの下限として扱う。
- オフライン本文の閲覧はアプリ内で完結させ、外部通信は情報源・公式リンクの明示的な操作に限る。
- 未監修フィクスチャを実際の緊急時手順に見える文面へ広げない。
- 緊急カードの採用項目は連絡先・集合/避難・アレルギー・常用薬・注意メモ・任意表示名のみ。
- アプリ内ロックは既定オフ。端末ロックを主防御とし、可用性を優先する。
- 緊急カードの iCloud 同期は採用しない。
- PDF の既定選択に個人情報を含めない。ファイル名に個人情報を入れない。
- `DEVELOPMENT_TEAM` は `project.yml` に書かず、Xcode で本人が選ぶ。

## Tests

- `swift test --disable-sandbox`: 60 tests / 11 suites 成功。
- `FourteenDayNoteMac` の未署名 Debug build: 成功。
- `content-lint --distribution`: draft 混在で exit 2（期待どおり）。

## Risks / Unknowns

- iOS Platform 未導入のため iOS ビルド・シミュレータ・実機未実施。
- 実機30秒計測と VoiceOver / 最大 Dynamic Type の記録が残る。
- 失効した Development 証明書（lero003@gmail.com）がローカル identity に残っている。有効な Keitaro Matsukura 側を使うこと。
- Release Archive の Validate は未実行。

## Next Actions

1. Xcode Components で iOS Platform を入れ、Simulator build と `docs/MANUAL_SMOKE_CHECKLIST.md` を実施する。
2. `docs/TESTFLIGHT_HANDOFF.md` に従い Team / Archive / Validate / 内部TestFlight Upload を本人が行う。
3. 記事拡充・監修フェーズへ進み、一般公開前に `content-lint --distribution` を通す。

## Avoid

- 監修前の記事を正式な防災・医療・食品衛生情報として扱わない。
- 端末のアクセシビリティ文字サイズをアプリ設定で縮小しない。
- 備蓄データと緊急カードの個人情報を同じ保存境界へ混ぜない。
- 個人情報をログ・エラー文・PDFファイル名へ出さない。
- Team ID やフィードバックメールを推測で固定しない。
