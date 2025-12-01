defmodule BloodPressureRecordWeb.BloodPressureLive.Index do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Blood pressures
        <:actions>
          <.button variant="primary" navigate={~p"/blood_pressures/new"}>
            <.icon name="hero-plus" /> New Blood pressure
          </.button>
        </:actions>
      </.header>

      <.table
        id="blood_pressures"
        rows={@streams.blood_pressures}
        row_click={fn {_id, blood_pressure} -> JS.navigate(~p"/blood_pressures/#{blood_pressure}") end}
      >
        <:col :let={{_id, blood_pressure}} label="Systolic">{blood_pressure.systolic}</:col>
        <:col :let={{_id, blood_pressure}} label="Diastolic">{blood_pressure.diastolic}</:col>
        <:col :let={{_id, blood_pressure}} label="Pulse">{blood_pressure.pulse}</:col>
        <:col :let={{_id, blood_pressure}} label="Measured at">{blood_pressure.measured_at}</:col>
        <:action :let={{_id, blood_pressure}}>
          <div class="sr-only">
            <.link navigate={~p"/blood_pressures/#{blood_pressure}"}>Show</.link>
          </div>
          <.link navigate={~p"/blood_pressures/#{blood_pressure}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, blood_pressure}}>
          <.link
            phx-click={JS.push("delete", value: %{id: blood_pressure.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Blood pressures")
     |> stream(:blood_pressures, list_blood_pressures())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    blood_pressure = BloodPressures.get_blood_pressure!(id)
    {:ok, _} = BloodPressures.delete_blood_pressure(blood_pressure)

    {:noreply, stream_delete(socket, :blood_pressures, blood_pressure)}
  end

  defp list_blood_pressures() do
    BloodPressures.list_blood_pressures()
  end
end
