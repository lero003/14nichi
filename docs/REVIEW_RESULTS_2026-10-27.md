# v1.2 独立レビュー・改修結果

確認日: 2026-10-27 / 起点: `5b97f52` / 対象: iOS `1.2.0 (7)` 提出前候補

## 目的と結論

防災ガイドの鮮度、既存実装の不具合、iPhone Duoの開閉に伴う画面幅変更を確認した。30記事の本文を読み、公的一次情報と照合した結果、全面改稿や記事増加は不要だが、10記事の安全条件・誤記を修正する必要があった。出典の差替・追加を含め13記事の編集確認日を更新した。`approved` は編集確認であり、専門資格者による個別監修や正確性保証ではない。

Duo対応の実装では、サイズクラスでレイアウトを切り替え、記事・検索・選択と記事内の読書位置を保持する。実Duoの開閉・pose・非対称セーフエリアの確認は別ゲートとする。

## 確認した問題と改修

| 優先度 | 問題 | 改修 |
|---|---|---|
| P1 | 停電時に「転倒しやすい場所に物を置く」という逆の指示 | 通路・足元に物を置かず、ライトで足元を確認する |
| P1 | 余震時に転倒しやすい家具を壁から離すという根拠のない指示 | 人が家具から離れ、安全な寝床・避難経路を確保。固定・配置変更は安全確保後 |
| P1 | 「密閉した室内」だけで発電機を禁止し、換気すれば屋内可と読める | 換気にかかわらず屋内・車内・テント内不可。屋外でも開口部から離す |
| P1 | CO中毒疑い時が「必要なら救急」 | 安全な空気のある場所へ退避・119番・軽快しても受診・危険箇所へ戻らない |
| P1 | 火が使えない状況でも「安全そうな生もの」を優先し得る | 必要な加熱ができ、保存温度を保てた食品に限定。温度不保持・完全解凍後の再凍結を避ける |
| P1 | 洪水時の屋内安全確保を高い階だけで判断し得る | 想定区域外・浸水しない居室・浸水長期化への備えを確認。津波・土砂では危険区域から離れる |
| P2 | 警戒レベル3・4の行動が曖昧 | 3で高齢者等と支援者、4で危険な場所から全員避難、5を待たないと明記 |
| P2 | 無条件の機内モード推奨で緊急速報が受信できない | 低電力モードを先にし、機内モードは代替情報源の確保が条件と明記 |
| P2 | 断水・浸水後の飲用再開条件と旧厚労省窓口 | 自治体等の飲用可案内を確認。水道水質の現所管である環境省へ案内を差替 |
| P2 | shortcutArticleIDだけtrim検証し実行時は生値で解決 | 生のIDを完全一致で検証。nilのみ未指定。前後空白・改行・空文字等の5入力を回帰テスト |
| P2 | compact/regularのView再生成で読書位置が消える | ブラウザ側で記事別アンカーをメモリ保持し、同じscrollPositionでジャンプ・復元 |
| P2 | 見出しジャンプがVoiceOverフォーカスを移さない | アニメーション完了後に対象見出しへAccessibilityFocusStateを移す。最小タップ高44pt |
| P2 | 最優先バッジとヒーローの小文字にコントラスト不足 | 専用濃色・ivory文字へ限定変更。計算値6.100:1、ヒーロー最低5.595:1 |

優先度はこの保守レビューの製品影響であり、セキュリティ脆弱性の評価ではない。

## 既存実装を維持した判断

- `shortcutArticleID` のapproved・所属状況・immediate条件と、未指定時のcritical/immediateフォールバックは整合している。
- manifest titleと先頭H1の完全一致は、現在のCONTENT_CONTRACTに沿う。緩和しない。
- 目次ボタンとスクロール先の名前空間は整合している。
- deepTeal文字を残した箇所はivory背景と約9.207:1であり、一律差替は不要。
- カスタム選択カードにもselected traitは残る。キーボード操作の実機検証は別途必要で、静的確認だけで退行なしとは断定しない。
- 2026年5月開始の防災気象情報体系は既存3記事へ反映され、現在の気象庁資料と整合している。

## 記事別の確認範囲

全30記事の本文を読了したが、全出典の全文を再取得できた意味ではない。今回更新した記事のreviewedByにはCodexによる編集確認と明記した。既存sourceのaccessedAtは今回実際に開いて読めた資料だけ更新し、未取得のものは据え置いた。編集確認日も一括更新していない。従前は7/20・7/22・8/14が混在し、旧引継ぎの「全30記事を8/14確認」はmanifestと一致しない。

| article ID | タイトル | 判断 |
|---|---|---|
| `earthquake-first-actions` | 地震：最初の数分ですること | 本文維持 |
| `earthquake-aftershocks-home` | 地震：余震と在宅の安全確認 | 本文修正・出典確認 |
| `blackout-first-actions` | 停電：最初に確認すること | 本文修正・出典確認 |
| `blackout-phone-battery` | 停電：スマホの電池を延ばす | 本文修正・出典確認 |
| `blackout-food-fridge` | 停電：冷蔵・冷凍食品の扱い | 本文修正・出典確認 |
| `water-outage-first-actions` | 断水：最初にすること | 本文修正・出典確認 |
| `water-outage-toilet-hygiene` | 断水時のトイレと衛生 | 本文維持 |
| `water-priority-uses` | 水の使い方の優先順位 | 本文維持・出典差替/追加 |
| `communication-first-actions` | 通信しづらいときの最初の行動 | 本文維持 |
| `communication-family-plan` | 家族の連絡と集合の決め方 | 本文維持 |
| `flood-first-actions` | 大雨・洪水：早めの行動 | 本文維持 |
| `flood-evacuation-timing` | 避難情報と動き出すタイミング | 本文修正・出典確認 |
| `heat-first-actions` | 猛暑・熱中症：身を守る | 本文維持 |
| `cold-first-actions` | 寒波：低体温を防ぐ | 本文修正・出典確認 |
| `gas-outage-first-actions` | ガスが止まった・臭いがするとき | 本文維持 |
| `shelter-in-place-basics` | 在宅避難で数日を過ごす | 本文維持 |
| `evacuation-go-bag` | 持ち出し袋の整え方 | 本文維持 |
| `evacuation-decision` | 避難する・留まるの判断 | 本文修正・出典確認 |
| `misinfo-check-steps` | 情報が錯綜しているときの確認手順 | 本文維持・出典差替/追加 |
| `first-aid-call-119` | 救急を呼ぶ判断の目安 | 本文維持 |
| `first-aid-bleeding-basics` | 出血があるときの基本 | 本文維持 |
| `first-aid-medications-shortage` | 常用薬が足りないとき | 本文維持 |
| `preparedness-stockpile-basics` | 家庭備蓄の始め方 | 本文維持 |
| `preparedness-emergency-card` | 緊急カードに書いておくこと | 本文維持 |
| `preparedness-official-info` | 平時に確認しておく公式情報 | 本文維持 |
| `food-no-cook-priority` | 火が使えないときの食事の順番 | 本文修正・出典確認 |
| `hygiene-without-bathing` | 入浴できないときの清潔 | 本文維持・出典差替/追加 |
| `earthquake-tsunami-coast` | 沿岸部：津波が心配なとき | 本文維持 |
| `blackout-fire-safety` | 停電時の火気と一酸化炭素 | 本文修正・出典確認 |
| `shelter-day7-to-day14` | 1〜2週目の生活を立て直す | 本文維持 |

## 新規・更新根拠

以下は確認日2026-10-27、本文は自前の要約、長い原文・図表の転載なし。publisher・accessedAt・usage・rightsNoteをmanifestへ記録した。

- [農林水産省 災害時の食中毒への注意](https://www.maff.go.jp/j/fs/foodpois_flooding.html): 2026-09-08作成。停電時の食品温度・廃棄・再凍結、断水/浸水後の飲用可確認。
- [消費者庁 停電時の発電機・通電火災](https://www.caa.go.jp/policies/policy/consumer_safety/caution/caution_070/): 屋内使用禁止と屋外開口部からの距離。
- [日本赤十字社 中毒](https://www.jrc.or.jp/study/safety/poison/): ガス中毒疑い時の安全確保、119番と診療。
- [大阪府 その他の地震対策](https://www.pref.osaka.lg.jp/o130040/kenshi_kikaku/kikaku_bousai/interior.html): 家具固定と安全空間。
- [国土交通省 緊急速報メールの注意](https://www.mlit.go.jp/report/press/mizukokudo03_hh_001176.html): 機内モード時は受信不可。
- [内閣府 避難情報ガイドライン](https://www.bousai.go.jp/oukyu/hinanjouhou/r3_hinanjouhou_guideline/index.html)と令和8年3月本文: レベル3・4行動、§2.3.2屋内安全確保。
- [気象庁 新たな防災気象情報](https://www.jma.go.jp/jma/kishou/know/bosai/keiho-update2026/index.html): 名称・開始時期と8/28更新チラシの整合確認。
- [環境省 水道対策](https://www.env.go.jp/water/water_supply/index.html): 旧厚労省水道窓口から現所管への参照先差替（linkOnly）。
- [厚労省 避難所生活で健康に過ごすために](https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000212521_00003.html): 手指・口腔衛生の直接根拠。
- [広報ぼうさい 災害時の偽・誤情報](https://www.bousai.go.jp/kohou/kouhoubousai/r05/109/news_03.html): 発信元・日時・一次情報と拡散抑制の直接根拠。

既存sourceの実読対象は、津波案内、新防災気象情報、避難情報ガイドライン、キキクル、ハザードポータル、内閣府家庭備えチェック、農水省家庭備蓄、首相官邸防災入口、国民保護入口、総務省災害用伝言、消防研究センター、食品衛生/ヒスタミン、飲用制限、携帯トイレ、手洗い、熱中症、低体温/保温、救急相談/講習、直接圧迫止血、災害時医薬品。一般ポータルの閲覧と、個別主張の裏付けを区別した。

再取得できなかった既存出典:

- 政府広報の旧preparation URL: HTTP 403。リンク切れとは断定せず、旧accessedAt維持。
- 経済産業省ガス臭ページ: 直接取得403。検索索引は参照できたが全文再確認とは扱わない。
- 厚労省の避難所低体温PDF: 取得上限超過。採用している保温の原則は消防庁・日赤の別出典で確認。
- 全汎用ポータルの全文や全リンク先を再読したものではない。

## Duo対応の範囲

[AppleのDuo技術資料](https://developer.apple.com/videos/play/tech-talks/111461/)に従い、端末名・固定画面寸法・向きからの推定を追加せず、horizontalSizeClassと標準ナビゲーション・セーフエリアに従う。既存のiPhone横向き設定とiOS 27.1 SDKでビルドする構成を維持。

- 記事別の読書位置はブラウザのメモリにのみ保持し、保存データ形式は追加しない。
- ガイド以外のHome・備え・買い物・緊急カード・出力・設定もコードレビューした。UIScreen.main、端末名/idiomによる固定判定、操作要素のセーフエリア無視はなく、追加の確定不具合は見つからなかった。実機での編集・認証・共有中の開閉確認は残る。
- regularで選んだ状況/記事をcompactルートにも同期する。
- DEBUG限定のiPad回帰ホストは、同じブラウザを390pt/利用可能幅とcompact/regularで実行中に往復させる。通常起動・Releaseには出ない。
- ローカルはXcode 27.1 / iOS 27.1 SDK、実行可能runtimeはiOS 27.0。Duo device typeは27.1以上必須。27.1 runtime取得は低速のため中断した。
- 回帰ホストは実Duoのpose・非対称セーフエリア・外側画面の代用ではない。Duo Simulator/実機、iOS 18、VoiceOver実機、外付けキーボードは未検証。

## 検証

- `swift test --disable-sandbox`: **85 tests / 14 suites 成功**（パラメータ化テストで不正ID 5入力を確認）。
- `swift run content-lint` / `swift run content-lint --distribution`: **13状況・30記事、全件approvedで成功**。
- `xcodegen generate`: 成功。schemeは以下すべて `FourteenDayNote`。
- `xcodebuild ... -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`: 成功。
- `xcodebuild ... -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`: 成功。
- iPhone 17 / iOS 27.0: **既存XCUITest 8件成功**（最終 `/tmp/14nichi-iphone-final.xcresult`）。
- iPad Pro 11-inch (M4) / iOS 27.0: **追加XCUITest 3件成功**（最終 `/tmp/14nichi-ipad-final.xcresult`）。同じ起動中のcompact→regular→compactで、ジャンプ先・手動スクロール位置・検索語と選択記事・結果への戻りを検証。
- Release生成物: Bundle ID `jp.hazakura.FourteenDayNote`、`1.2.0 (7)`、SDK `iphonesimulator27.1`、device families `[1,2]`、iPhone横向き対応、Privacy Manifest同梱を確認。
- iPhone 17 Simulatorのdark + 最大Dynamic Typeで記事上部を目視確認。タイトル・メタ情報は折り返し、読みやすさ/About/お気に入りのツールバーを表示。本文全域の操作・VoiceOver実機の合格を意味しない。
- `git diff --check`: 成功。統合diffの別エージェントレビューで追加ブロッカーなし。

Xcodeの既知出力: ビルド時のAppIntentsメタデータ抽出スキップ。UI実行ログには `IDESchemeActionSDKRecord` の `invalidDigitCount(94232)` とdebugger version lookupの診断も出たが、最終のtest actionは成功した。警告なしとは扱わない。テスト失敗時の巨大diagnostics採取を避けるため `-collect-test-diagnostics never` を指定した。

最終UIテストは同じプロジェクト・scheme・Debug・unsignedで `-parallel-testing-enabled NO` を指定。iPhoneは追加3件をskipし、iPadは追加3件だけを `-only-testing` で実行。結果bundleとログは一時検証資料であり、永続的な配布物ではない。

## 未実施ゲート

- 実Duoまたは対応Simulatorで閉じる/開く/折る/回転/Split Viewと左右の操作領域を確認。
- 実機VoiceOver（ジャンプ先読み上げを含む）、最大Dynamic Type、Reduce Motion、機内モード30秒、iPadキーボード。
- 最終Release候補のApp Store画像再撮影、Archive / Validate / Upload / Connect提出。

バージョンは未提出候補の1.2.0 (7)を維持。公開済みタグ、Team ID、永続ストア、備蓄数量の計算、ネットワーク/SDKは変更していない。元のレビュー依頼は `REVIEW_BRIEF_2026-10-27.md`。
