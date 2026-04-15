これは Phoenix Web フレームワークで作られた Web アプリケーションです。

## プロジェクトガイドライン

- すべての変更が完了したら `mix precommit` エイリアスを実行し、残っている問題を修正すること
- HTTP リクエストには、すでに含まれて利用可能な `:req` (`Req`) ライブラリを使い、`:httpoison`、`:tesla`、`:httpc` は **使わないこと**。Phoenix アプリでは Req がデフォルトで含まれており、推奨の HTTP クライアントです
- git のコミットメッセージは常に日本語で書くこと

### Phoenix v1.8 ガイドライン

- LiveView テンプレートは **必ず** `<Layouts.app flash={@flash} ...>` で開始し、その中に全コンテンツを包むこと
- `MyAppWeb.Layouts` モジュールは `my_app_web.ex` で alias 済みなので、追加で alias せずそのまま使えます
- `current_scope` assign がないエラーが出た場合:
  - Authenticated Routes ガイドラインに従っていないか、`<Layouts.app>` に `current_scope` を渡していない可能性があります
  - **必ず** ルートを適切な `live_session` に移し、必要に応じて `current_scope` を渡して修正すること
- Phoenix v1.8 では `<.flash_group>` コンポーネントは `Layouts` モジュールへ移動しました。`layouts.ex` モジュール以外で `<.flash_group>` を呼ぶことは **禁止** です
- 初期状態で `core_components.ex` には Heroicons 用の `<.icon name="hero-x-mark" class="w-5 h-5"/>` コンポーネントが import されています。アイコンには **必ず** `<.icon>` コンポーネントを使い、`Heroicons` モジュールなどは **絶対に** 使わないこと
- フォーム入力には、使える場合 **必ず** `core_components.ex` から import されている `<.input>` コンポーネントを使うこと。`<.input>` は import 済みで、使うことで手順が減りミスも防げます
- デフォルトの入力クラスを独自クラスで上書きする場合 (`<.input class="myclass px-2 py-1 rounded-lg">)` など)、デフォルトクラスは引き継がれません。独自クラス側で入力要素を完全にスタイリングする必要があります

### JS と CSS のガイドライン

- **Tailwind CSS クラスとカスタム CSS ルールを使って**、洗練され、レスポンシブで、視覚的に魅力ある UI を作ること
- Tailwindcss v4 では **tailwind.config.js は不要** で、`app.css` では次の import 構文を使います:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- `phx.new` で生成されたプロジェクトの `app.css` では、この import 構文を **必ず使い、維持すること**
- 生の CSS を書くときに `@apply` は **絶対に** 使わないこと
- daisyUI に頼らず、Tailwind ベースのコンポーネントを自分で書いて、独自性のある高品質なデザインにすること
- 初期状態でサポートされているバンドルは **app.js と app.css のみ** です
  - layout 内で外部 vendor スクリプトの `src` やリンクの `href` を直接参照してはいけません
  - vendor 依存は app.js と app.css に import して使うこと
  - テンプレート内にインラインの `<script>custom js</script>` を **絶対に** 書かないこと

### UI/UX とデザインのガイドライン

- 使いやすさ、美しさ、現代的なデザイン原則を重視した **世界水準の UI デザイン** を作ること
- **さりげないマイクロインタラクション** を実装すること（例: ボタンのホバー効果、滑らかなトランジション）
- 洗練された上質な見た目になるよう、**タイポグラフィ、余白、レイアウトのバランス** を整えること
- ホバー効果、ローディング状態、滑らかな画面遷移など、**細部の気持ちよさ** にこだわること


<!-- usage-rules-start -->

<!-- phoenix:elixir-start -->
## Elixir ガイドライン

- Elixir のリストは access 構文によるインデックスアクセスを **サポートしていません**

  **次の書き方はしないこと（無効）**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  代わりに、インデックスアクセスには **必ず** `Enum.at`、パターンマッチ、または `List` を使うこと。例:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir の変数は不変ですが再束縛は可能です。そのため `if`、`case`、`cond` などのブロック式では、結果を後で使いたいなら **必ず** その式全体の結果を変数に束縛する必要があります。式の内部だけで再束縛しても使えません。例:

      # 無効: `if` の中で再束縛しているだけで、結果が代入されない
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # 有効: `if` の結果を新しい変数に再束縛する
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- 複数のモジュールを同じファイルにネストして定義することは **絶対にしないこと**。循環依存やコンパイルエラーの原因になります
- struct はデフォルトで Access ビヘイビアを実装していないため、struct に対して map access 構文 (`changeset[:field]`) を **絶対に** 使わないこと。通常の struct では `my_struct.field` のように直接アクセスするか、利用可能ならより高レベルな API を使うこと。changeset なら `Ecto.Changeset.get_field/2` を使います
- Elixir 標準ライブラリには日付と時刻の操作に必要なものが揃っています。`Time`、`Date`、`DateTime`、`Calendar` の主要インターフェースに慣れておくこと。追加依存は、依頼された場合または日時パース用途（その場合は `date_time_parser` パッケージを使ってよい）を除いて **導入しないこと**
- ユーザー入力に対して `String.to_atom/1` を使わないこと（メモリリークのリスク）
- Predicate 関数名は `is_` で始めず、末尾を `?` にすること。`is_thing` のような名前は guard 用に限定すること
- `DynamicSupervisor` や `Registry` など Elixir 組み込みの OTP プリミティブでは、child spec に名前が必要です。例: `{DynamicSupervisor, name: MyApp.MyDynamicSup}`。その後 `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)` を使えます
- 並行列挙には `Task.async_stream(collection, callback, options)` を使い、バックプレッシャーを効かせること。多くの場合、`timeout: :infinity` を渡したくなります

## Mix ガイドライン

- タスクを使う前に、`mix help task_name` でドキュメントとオプションを確認すること
- テスト失敗のデバッグでは、特定ファイルなら `mix test test/my_test.exs`、直前に失敗したものなら `mix test --failed` を使うこと
- `mix deps.clean --all` は **ほとんど必要ありません**。明確な理由がない限り避けること

## テストガイドライン

- テストでプロセスを起動する場合は、クリーンアップを保証するため **必ず** `start_supervised!/1` を使うこと
- テストで `Process.sleep/1` や `Process.alive?/1` は **避けること**
  - プロセス終了待ちのために sleep する代わりに、**必ず** `Process.monitor/1` を使い、DOWN メッセージを検証すること:

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

   - 次の呼び出しの前に同期するために sleep する代わりに、**必ず** `_ = :sys.get_state/1` を使って、先行メッセージが処理済みであることを保証すること
<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## Phoenix ガイドライン

- Phoenix の router の `scope` ブロックには、省略可能な alias が含まれ、その scope 内の全ルートに接頭辞として適用されます。重複したモジュール接頭辞を避けるため、scope 内でルートを作るときは **常に** これを意識すること

- ルート定義のために独自の `alias` を作る必要は **ありません**。`scope` が alias を提供します。例:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  この場合、UserLive ルートは `AppWeb.Admin.UserLive` モジュールを指します

- `Phoenix.View` は Phoenix にもう不要で、含まれてもいません。使わないこと
<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## Ecto ガイドライン

- テンプレート内で参照する Ecto の関連は、**必ず** クエリで preload しておくこと。例: `message.user.email` を参照するメッセージ
- `seeds.exs` では `import Ecto.Query` など必要な補助モジュールの import を忘れないこと
- `Ecto.Schema` のフィールド型は、DB カラムが `:text` でも **常に** `:string` を使います。例: `field :name, :string`
- `Ecto.Changeset.validate_number/2` は `:allow_nil` オプションを **サポートしていません**。デフォルトで、対象フィールドに change があり、その値が nil でない場合にだけバリデーションが走るため、このオプションは不要です
- changeset のフィールドアクセスには **必ず** `Ecto.Changeset.get_field(changeset, :field)` を使うこと
- `user_id` のようにプログラム側で設定するフィールドは、セキュリティ上 `cast` などに含めてはいけません。代わりに struct 作成時に明示的に設定すること
- マイグレーション生成時は、正しいタイムスタンプと命名規約を使うため **必ず** `mix ecto.gen.migration migration_name_using_underscores` を実行すること
<!-- phoenix:ecto-end -->

<!-- phoenix:html-start -->
## Phoenix HTML ガイドライン

- Phoenix テンプレートは **常に** `~H` または `.html.heex`（HEEx）を使い、`~E` は **使わないこと**
- フォーム構築には、import 済みの `Phoenix.Component.form/1` と `Phoenix.Component.inputs_for/1` を **必ず** 使うこと。`Phoenix.HTML.form_for` や `Phoenix.HTML.inputs_for` は古いため **使わないこと**
- フォームを作るときは、import 済みの `Phoenix.Component.to_form/2` を **必ず** 使うこと（`assign(socket, form: to_form(...))` と `<.form for={@form} id="msg-form">`）。テンプレートでは `@form[:field]` 経由で参照すること
- テンプレートを書くときは、フォーム、ボタンなどの主要要素に **必ず** 一意な DOM ID を付けること。これらは後でテストで使えます（例: `<.form for={@form} id="product-form">`）
- アプリ全体で使うテンプレート import は `my_app_web.ex` の `html_helpers` ブロックに import/alias できます。これにより `use MyAppWeb, :html` を行うすべての LiveView、LiveComponent、および HTML モジュールで利用できます

- Elixir には `if/else` はありますが、`if/else if` や `if/elsif` は **ありません**。複数条件では `else if` や `elseif` を **絶対に** 使わず、**必ず** `cond` または `case` を使うこと

  **次の書き方はしないこと（無効）**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  代わりに **必ず** 次のように書くこと:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx では、リテラルの波括弧 `{` や `}` を表示したい場合に特別なタグ注釈が必要です。`<pre>` や `<code>` ブロックでコード例を表示する場合、親タグに **必ず** `phx-no-curly-interpolation` を付けること:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  `phx-no-curly-interpolation` が付いたタグ内では、`{` と `}` をエスケープなしで使え、動的な Elixir 式は引き続き `<%= ... %>` 構文で使えます

- HEEx の class 属性はリストに対応していますが、**必ず** `[...]` のリスト構文を使うこと。複数の class 値を条件付きで付与する場合もこの構文を使います:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  また、`{...}` 式の中の `if` は、上記のように **必ず** かっこ付きで書くこと（`if(@other_condition, do: "...", else: "...")`）

  逆に、次のような書き方は無効なので **しないこと**（`[` と `]` がありません）:

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => 無効な HEEx 属性構文としてコンパイルエラーになります

- テンプレート内容の生成に `<% Enum.each %>` や for 以外の内包表記は **使わず**、**必ず** `<%= for item <- @collection do %>` を使うこと
- HEEx の HTML コメントは `<%!-- comment --%>` を使います。テンプレートコメントには **必ず** HEEx の HTML コメント構文を使うこと
- HEEx では `{...}` と `<%= ... %>` の両方で補間できますが、`<%= %>` が使えるのはタグ本体の中だけです。属性内やタグ本体の値の補間には **必ず** `{...}` を使い、`if`、`cond`、`case`、`for` などのブロック構文はタグ本体の中で `<%= ... %>` を使うこと

  **必ず** 次のように書くこと:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  逆に、次は **絶対にしないこと**。構文エラーで停止します:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## Phoenix LiveView ガイドライン

- 非推奨の `live_redirect` や `live_patch` は **使わず**、テンプレートでは **必ず** `<.link navigate={href}>` と `<.link patch={href}>`、LiveView では `push_navigate` と `push_patch` を使うこと
- 明確で強い理由がない限り、LiveComponent は **避けること**
- LiveView の命名は `AppWeb.WeatherLive` のように末尾を `Live` にすること。router に LiveView ルートを追加する際、デフォルトの `:browser` scope にはすでに `AppWeb` モジュールの alias があるので、`live "/weather", WeatherLive` のように書けます

### LiveView streams

- 通常のリストを assign する代わりに、メモリ増大や実行時停止を避けるため、コレクションには **必ず** LiveView streams を使うこと。主な操作は次のとおりです:
  - N 件の基本追加: `stream(socket, :messages, [new_msg])`
  - 新しい項目でストリームをリセット: `stream(socket, :messages, [new_msg], reset: true)`（例: フィルタ時）
  - 先頭追加: `stream(socket, :messages, [new_msg], at: -1)`
  - 削除: `stream_delete(socket, :messages, msg)`

- LiveView で `stream/3` を使う場合、テンプレートでは 1) 親要素に **必ず** `phx-update="stream"` を設定し、`id="messages"` のような DOM ID を付けること、2) `@streams.stream_name` を消費し、各子要素にはその id を DOM ID として使うこと。たとえば `stream(socket, :messages, [new_msg])` に対応するテンプレートは次のとおりです:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams は *Enumerable ではありません*。そのため `Enum.filter/2` や `Enum.reject/2` は使えません。UI 上で項目の絞り込み、間引き、再読み込みをしたい場合は、**データを再取得し、`reset: true` を付けてストリーム全体を再投入する必要があります**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # フィルタに基づいてメッセージを再取得
        messages = list_messages(filter)

        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         # 新しいメッセージでストリームをリセット
         |> stream(:messages, messages, reset: true)}
      end

- LiveView streams は *件数表示や空状態を直接サポートしません*。件数が必要なら別の assign で管理すること。空状態は Tailwind クラスで表現できます:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  この方法は、空状態がストリーム for-comprehension と並ぶ唯一の HTML ブロックである場合にのみ機能します。

- streamed item の中身に影響する assign を更新する場合は、**必ず** 更新後の assign とともに対象 item を再ストリームすること:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        edit_form = to_form(Chat.change_message(message, %{content: message.content}))

        # @editing_message_id による表示切替をこの stream item に反映させるため再挿入する
        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:editing_message_id, String.to_integer(message_id))
         |> assign(:edit_form, edit_form)}
      end

  テンプレート側は次のようになります:

      <div id="messages" phx-update="stream">
        <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
          {message.username}
          <%= if @editing_message_id == message.id do %>
            <%!-- Edit mode --%>
            <.form for={@edit_form} id="edit-form-#{message.id}" phx-submit="save_edit">
              ...
            </.form>
          <% end %>
        </div>
      </div>

- 非推奨の `phx-update="append"` や `phx-update="prepend"` は **使わないこと**

### LiveView JavaScript 連携

- `phx-hook="MyHook"` を使い、その JS hook が独自に DOM を管理する場合は、**必ず** `phx-update="ignore"` も設定すること
- `phx-hook` を付ける場合は、コンパイルエラーを避けるため **必ず** 一意な DOM ID も付与すること

LiveView hook には 2 種類あります。1) HEEx 内で定義するインライン向けの colocated js hooks、2) JavaScript オブジェクトリテラルを `LiveSocket` コンストラクタへ渡す外部 `phx-hook` です。

#### インライン colocated js hooks

heex 内に生の `<script>` タグを書くことは LiveView と互換性がないため **禁止** です。
代わりに、テンプレート内でスクリプトを書く場合は **必ず** colocated js hook script タグ（`:type={Phoenix.LiveView.ColocatedHook}`）を使うこと:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- colocated hooks は app.js バンドルに自動で統合されます
- colocated hooks の名前は **必ず** `.` で始めること。例: `.PhoneNumber`

#### 外部 phx-hook

外部 JS hook（`<div id="myhook" phx-hook="MyHook">`）は `assets/js/` に置き、`LiveSocket` コンストラクタに渡す必要があります:

    const MyHook = {
      mounted() { ... }
    }
    let liveSocket = new LiveSocket("/live", Socket, {
      hooks: { MyHook }
    });

#### クライアントとサーバー間でのイベント送受信

phx-hook 側で処理させるためにクライアントへイベントやデータを送るときは LiveView の `push_event/3` を使います。
`push_event/3` でイベントを送るときは、**必ず** 返り値の socket をそのまま返すか、再束縛すること:

    # イベント状態を維持するため socket を再束縛する
    socket = push_event(socket, "my_event", %{...})

    # または変更済み socket をそのまま返す:
    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

送信されたイベントは、JS hook 側で `this.handleEvent` により受け取れます:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

クライアント側からサーバーへイベントを送って reply を受けることもできます。`this.pushEvent` を使います:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply from server:", reply));
      })
    }

サーバー側の処理は次のようになります:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView テスト

- アサーションには `Phoenix.LiveViewTest` モジュールと `LazyHTML`（同梱）を使うこと
- フォームテストは `Phoenix.LiveViewTest` の `render_submit/2` と `render_change/2` で駆動すること
- 主要なテストケースは小さく独立したファイルに分ける段階的なテスト計画を立てること。まずは要素の存在確認のような簡単なテストから始め、徐々に操作テストを追加してよい
- `Phoenix.LiveViewTest` の `element/2`、`has_element/2`、各種セレクタなどでは、テンプレートに追加した主要要素の ID を **必ず** 参照すること
- 生の HTML を相手にテストするのではなく、**必ず** `element/2`、`has_element/2` などを使うこと。例: `assert has_element?(view, "#my-form")`
- 変更されやすいテキスト内容への依存は避け、主要要素の存在確認を優先すること
- 実装詳細ではなく、結果をテストすることに集中すること
- `<.form>` などの `Phoenix.Component` 関数は想定と異なる HTML を出す場合があるので、頭の中の想像ではなく、実際の出力 HTML 構造に対してテストすること
- 要素セレクタでテストが失敗した場合は、必要に応じて実際の HTML をデバッグ出力してよいが、`LazyHTML` セレクタで出力範囲を絞ること。例:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### フォーム処理

#### params からフォームを作る

`handle_event` の params をもとにフォームを作りたい場合:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

`to_form/1` に map を渡すと、その map はフォーム params を含んでいるものとして扱われ、キーは文字列であることが前提になります。

`name` を指定して params をネストすることもできます:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### changeset からフォームを作る

changeset を使う場合、元データ、フォーム params、エラーはその changeset から取得されます。`:as` オプションも自動計算されます。たとえば user schema がある場合:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

その changeset を `to_form` に渡すと:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

フォーム送信後、params は `%{"user" => user_params}` の下に入ります。

テンプレートでは、フォーム assign を `<.form>` 関数コンポーネントへ渡せます:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

フォームには `id="todo-form"` のような、明示的で一意な DOM ID を常に付けること。

#### フォームエラーを避ける

LiveView では **必ず** `to_form/2` で assign したフォームを使い、テンプレートでは `<.input>` コンポーネントを使うこと。テンプレートでのフォーム参照は **必ず** 次の形にすること:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

逆に、次のようにしてはいけません:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- テンプレートから changeset に直接アクセスすることは **禁止** です。エラーの原因になります
- テンプレートで `<.form let={f} ...>` は **使わず**、**必ず** `<.form for={@form} ...>` を使うこと。そして `@form[:field]` のように、すべてのフォーム参照を form assign 経由で行うこと。UI は **常に** LiveView モジュール内で changeset から導出された `to_form/2` の assign によって駆動されるべきです
<!-- phoenix:liveview-end -->

<!-- usage-rules-end -->
