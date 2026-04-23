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

## Docker 起動（公開ポート 4100）

前提:

- DB はコンテナ外（ホスト）にある `blood_pressure_record_dev.db` をそのまま使う
- AI はホストで Ollama を起動しておく（コンテナから見える待受アドレスで起動）

例:

```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
ollama pull gemma3:27b
```

起動:

```bash
docker compose up -d --build
```

アクセス先:

- `http://localhost:4100`
- 開発用ダッシュボード: `http://localhost:4100/dev/dashboard`

停止:

```bash
docker compose down
```

### rootless Docker でログイン不要の自動起動にする

`rootless Docker` は通常 `systemd --user` で動作するため、`linger` が無効だとログイン中しかユーザーサービスが起動しません。  
`linger` は「ユーザーがログインしていなくても `systemd --user` を動かし続ける」設定です。

設定例（ユーザー名は `<your_username>` に置き換え）:

```bash
sudo loginctl enable-linger <your_username>
systemctl --user enable --now docker
docker update --restart unless-stopped blood_pressure_record-web
```

確認:

```bash
loginctl show-user <your_username> -p Linger
systemctl --user is-enabled docker
docker inspect -f '{{.Name}} -> {{.HostConfig.RestartPolicy.Name}}' blood_pressure_record-web
```

トラブルシュート（AI が動作しない場合）:

- コンテナ内疎通確認:

```bash
docker compose exec -T web curl -sS http://host.docker.internal:11434/api/tags
```

- 失敗する場合は、Ollama が `127.0.0.1` のみで待受している可能性があるため、`OLLAMA_HOST=0.0.0.0:11434` で起動する

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
