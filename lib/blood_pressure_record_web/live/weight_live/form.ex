defmodule BloodPressureRecordWeb.WeightLive.Form do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.Weights
  alias BloodPressureRecord.Weights.Weight

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>体重の記録を管理します。</:subtitle>
      </.header>

      <.form for={@form} id="weight-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:weight]} type="number" label="体重(kg)" step="0.1" />
        <.input field={@form[:measured_at]} type="datetime-local" label="測定日時" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">保存</.button>
          <.button navigate={return_path(@return_to, @weight)}>キャンセル</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    weight = Weights.get_weight!(id)

    socket
    |> assign(:page_title, "体重を編集")
    |> assign(:weight, weight)
    |> assign(:form, to_form(Weights.change_weight(weight)))
  end

  defp apply_action(socket, :new, _params) do
    weight = %Weight{measured_at: NaiveDateTime.truncate(NaiveDateTime.local_now(), :second)}

    socket
    |> assign(:page_title, "体重を追加")
    |> assign(:weight, weight)
    |> assign(:form, to_form(Weights.change_weight(weight)))
  end

  @impl true
  def handle_event("validate", %{"weight" => weight_params}, socket) do
    changeset = Weights.change_weight(socket.assigns.weight, weight_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"weight" => weight_params}, socket) do
    save_weight(socket, socket.assigns.live_action, weight_params)
  end

  defp save_weight(socket, :edit, weight_params) do
    case Weights.update_weight(socket.assigns.weight, weight_params) do
      {:ok, weight} ->
        {:noreply,
         socket
         |> put_flash(:info, "更新しました")
         |> push_navigate(to: return_path(socket.assigns.return_to, weight))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_weight(socket, :new, weight_params) do
    case Weights.create_weight(weight_params) do
      {:ok, weight} ->
        {:noreply,
         socket
         |> put_flash(:info, "作成しました")
         |> push_navigate(to: return_path(socket.assigns.return_to, weight))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _weight), do: ~p"/weights"
  defp return_path("show", weight), do: ~p"/weights/#{weight}"
end
