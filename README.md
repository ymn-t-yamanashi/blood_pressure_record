# BloodPressureRecord

血圧・脈拍・体重を記録し、グラフと一覧で確認できる Phoenix LiveView アプリです。  
トップページの「AI記録」では、血圧計/体重計の画像（`.jpg`/`.jpeg`）をアップロードして値を読み取り、確認後に保存できます。

## 主な機能

- AI画像読み取りによる記録作成（血圧または体重）
- 血圧・体重の CRUD（一覧 / 作成 / 編集 / 詳細 / 削除）
- 日別の最新データ集計
- メトリクス切替可能なグラフ表示
- 最新記録のページング表示

## 画面 / ルート

- `/` または `/up`: AI記録画面
- `/blood_pressures`: 血圧一覧
- `/blood_pressures/new`: 血圧新規作成
- `/weights`: 体重一覧
- `/weights/new`: 体重新規作成

## 技術スタック

- Elixir `~> 1.15`
- Phoenix `~> 1.8.2`
- Phoenix LiveView `~> 1.1.0`
- Ecto + SQLite3
- Tailwind CSS / esbuild
- Ollama（AI読み取り）
- Evision（画像前処理）
- VegaLite（グラフ描画）

## 前提条件

- Elixir / Erlang がインストール済み
- 開発時は SQLite を利用（`blood_pressure_record_dev.db`）
- AI記録を使う場合は Ollama を起動し、モデル `gemma3:27b` を用意する

例:

```bash
ollama serve
ollama pull gemma3:27b
```

## セットアップ

```bash
mix setup
```

実行内容:

- 依存ライブラリ取得
- DB作成・マイグレーション・seed投入
- フロントエンドアセット準備とビルド

## 開発サーバー起動

```bash
mix phx.server
```

ブラウザで `http://localhost:4000` を開いてください。

## テストと品質チェック

```bash
mix test
mix precommit
```

`mix precommit` は以下を実行します。

- `compile --warnings-as-errors`
- `deps.unlock --unused`
- `format`
- `test`

## DB バックアップ

`backup/` ディレクトリを作成し、その配下に日付付きファイル名で SQLite DB をバックアップできます。

```bash
mix db.backup
```

## 補足

- 開発用ダッシュボード: `http://localhost:4000/dev/dashboard`
- 本番では `DATABASE_PATH`、`SECRET_KEY_BASE` などの環境変数が必要です（`config/runtime.exs` を参照）
