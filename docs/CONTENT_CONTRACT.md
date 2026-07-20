# Content Contract

## 配置

```text
Sources/FourteenDayCore/Resources/Content/
├── manifest.json
└── emergency/
    ├── earthquake-first-actions.md
    ├── blackout-first-actions.md
    ├── blackout-phone-battery.md
    ├── water-outage-first-actions.md
    └── communication-first-actions.md
```

検証コマンド:

```sh
swift run content-lint
swift run content-lint Sources/FourteenDayCore/Resources/Content
```

`manifest.json` がアプリの機械可読な索引です。Markdownのfront matterは編集者向けの写しとして残せますが、初期ローダーはmanifestを正とします。二重管理を解消する生成・検証ツールは次のスライスで追加します。

現在のローダーは、manifestとfront matterの `id` / `review_status` が一致しない記事を拒否します。また、重複ID、存在しない状況ID、不正な相対パス、監修情報が不足した `approved` 記事、不備のある出典も拒否します。

## 必須メタデータ

- `id`: リリース後に変更しない一意ID
- `title`: 画面表示名
- `summary`: 一覧で読める短い要約
- `path`: Contentディレクトリからの相対パス
- `category`: 大分類
- `priority`: `critical` / `high` / `normal`
- `situations`: 状況IDの配列
- `periods`: `immediate` / `day1` / `day3` / `day7` / `day14`
- `region`: 初期版は `jp`
- `reviewStatus`: `draft` / `reviewed` / `approved`
- `reviewedAt`: 最終確認日。未確認なら `null`
- `reviewedBy`: 確認主体。未確認なら `null`
- `sources`: 情報源配列（下記）

front matterには少なくとも次を置きます。

```yaml
---
id: earthquake-first-actions
review_status: draft
---
```

## 情報源（sources）

記事本文は原則として**自前の文章**にします。情報源は「どこを踏まえたか」を追跡し、権利上の扱いを明示するための記録です。URLを並べるだけでは不十分で、利用形態と権利注記まで必須です。

### フィールド

| フィールド | 必須 | 内容 |
|---|---|---|
| `id` | はい | 記事内で一意な出典ID |
| `title` | はい | 画面表示用の資料名 |
| `publisher` | はい | 発行主体（省庁・自治体・団体名） |
| `url` | はい | **https** の参照先 |
| `accessedAt` | はい | 最終確認日 `YYYY-MM-DD` |
| `usage` | はい | `linkOnly` / `paraphrase` / `shortQuote` |
| `rightsNote` | はい | 転載しない理由、利用条件、要約方針などの短い注記 |
| `excerpt` | `shortQuote` のみ | 120文字以内の短文引用。それ以外では置かない |

### usage の意味

| usage | 意味 | 許されること | 禁止に近いこと |
|---|---|---|---|
| `linkOnly` | 参照リンクのみ | 公式ページへの案内、発行者とURLの表示 | 相手サイト本文のコピー |
| `paraphrase` | 自前の言い換え・要約 | 公的案内を読み、自分の言葉で行動手順を書く | 原文の長い引き写し、構成の丸ごと複製 |
| `shortQuote` | 必要な最小限の短文引用 | 定義や固有名称など短い原文を `excerpt` に記録 | 120文字超、段落単位の転載、図表の無断利用 |

### 権利方針（クリアしたい線）

1. **一次情報を優先する**  
   内閣府、消防庁、厚労省、気象庁、自治体、日本赤十字社など、責任主体が明確な公的情報を優先する。

2. **転載より参照と要約**  
   相手サイトの文章・画像・PDFをアプリへ丸ごと入れない。必要なのは「利用者が辿れる出典」と「自前で整理した行動手順」。

3. **短文引用は例外**  
   どうしても原文が必要な場合だけ `shortQuote` とし、長さを抑え、引用であることが画面上で分かるようにする。

4. **商用・個人ブログ・SNSを根拠にしない**  
   二次情報は補助に留め、安全に関わる主張の唯一の根拠にしない。

5. **確認日を残す**  
   公的ページは更新される。`accessedAt` と `reviewedAt` を更新し、古い案内を製品として残さない。

6. **利用条件が不明なら書かない**  
   ライセンスや転載条件がはっきりしない資料は、リンクすら慎重にし、必要なら法務・権利確認後に追加する。

7. **draft でも嘘の出典を付けない**  
   制作フィクスチャに出典を付ける場合は、実際に参照する公式URLと `linkOnly` など実態に合う usage だけを使う。本文がまだフィクスチャなら、rightsNote にその旨を書く。

### 記入例

```json
{
  "id": "cao-bousai-portal",
  "title": "内閣府 防災情報のページ",
  "publisher": "内閣府",
  "url": "https://www.bousai.go.jp/",
  "accessedAt": "2026-07-20",
  "usage": "linkOnly",
  "rightsNote": "公式ポータルへの参照リンクのみ。本文は転載しない。",
  "excerpt": null
}
```

```json
{
  "id": "fdma-definition-sample",
  "title": "（例）用語定義の短文引用",
  "publisher": "総務省消防庁",
  "url": "https://www.fdma.go.jp/",
  "accessedAt": "2026-07-20",
  "usage": "shortQuote",
  "rightsNote": "用語確認のための最小限の引用。前後の解説は自前で書く。",
  "excerpt": "（120文字以内の原文のみ）"
}
```

### ローダー検証

出典が1件以上ある場合、各件について次を検証します。

- `id` / `title` / `publisher` / `rightsNote` が空でない
- `accessedAt` が実在する `YYYY-MM-DD` の日付
- `url` が `https`
- 記事内で `id` が重複しない
- `linkOnly` / `paraphrase` では `excerpt` を置かない
- `shortQuote` では `excerpt` 必須、かつ 120 文字以内

`approved` 記事は、上記に加えて監修日・確認者・1件以上の出典が必須です。

## 公開条件

記事を製品コンテンツとして扱うには、次をすべて満たす必要があります。

1. `reviewStatus` が `approved`。
2. 対象地域と想定状況が明示されている。
3. 安全に関わる主張が情報源で追跡できる。
4. 各情報源に publisher・accessedAt・usage・rightsNote がある。
5. 最終確認日と確認者が記録されている。
6. 「緊急通報・自治体等の指示を優先する条件」が必要な記事に明示されている。
7. オフライン表示、文字拡大、VoiceOverで内容を確認している。
8. 長い原文転載や権利不明の素材を含まない。

`draft` と `reviewed` は開発・校正用であり、App Store向けビルドへ含めない方針です。製品ビルドでの強制検証は、コンテンツ制作フローを固めた後に追加します。
