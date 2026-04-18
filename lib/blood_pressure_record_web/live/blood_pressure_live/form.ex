defmodule BloodPressureRecordWeb.BloodPressureLive.Form do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecord.BloodPressures.BloodPressure

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>血圧の記録を管理します。</:subtitle>
      </.header>

      <.form for={@form} id="blood_pressure-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:systolic]} type="number" label="最高血圧" />
        <.input field={@form[:diastolic]} type="number" label="最低血圧" />
        <.input field={@form[:pulse]} type="number" label="脈拍" />
        <.input field={@form[:measured_at]} type="datetime-local" label="測定日時" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">保存</.button>
          <.button navigate={return_path(@return_to, @blood_pressure)}>キャンセル</.button>
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
    blood_pressure = BloodPressures.get_blood_pressure!(id)

    socket
    |> assign(:page_title, "血圧を編集")
    |> assign(:blood_pressure, blood_pressure)
    |> assign(:form, to_form(BloodPressures.change_blood_pressure(blood_pressure)))
  end

  defp apply_action(socket, :new, _params) do
    today = Date.utc_today()
    measured_at = NaiveDateTime.new!(today, ~T[00:00:00])
    blood_pressure = %BloodPressure{measured_at: measured_at}

    socket
    |> assign(:page_title, "血圧を追加")
    |> assign(:blood_pressure, blood_pressure)
    |> assign(:form, to_form(BloodPressures.change_blood_pressure(blood_pressure)))
  end

  @impl true
  def handle_event("validate", %{"blood_pressure" => blood_pressure_params}, socket) do
    changeset =
      BloodPressures.change_blood_pressure(socket.assigns.blood_pressure, blood_pressure_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"blood_pressure" => blood_pressure_params}, socket) do
    save_blood_pressure(socket, socket.assigns.live_action, blood_pressure_params)
  end

  defp save_blood_pressure(socket, :edit, blood_pressure_params) do
    case BloodPressures.update_blood_pressure(
           socket.assigns.blood_pressure,
           blood_pressure_params
         ) do
      {:ok, blood_pressure} ->
        {:noreply,
         socket
         |> put_flash(:info, "更新しました")
         |> push_navigate(to: return_path(socket.assigns.return_to, blood_pressure))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_blood_pressure(socket, :new, blood_pressure_params) do
    case BloodPressures.create_blood_pressure(blood_pressure_params) do
      {:ok, blood_pressure} ->
        {:noreply,
         socket
         |> put_flash(:info, "作成しました")
         |> push_navigate(to: return_path(socket.assigns.return_to, blood_pressure))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _blood_pressure), do: ~p"/blood_pressures"
  defp return_path("show", blood_pressure), do: ~p"/blood_pressures/#{blood_pressure}"
end
