defmodule BloodPressureRecordWeb.BloodPressureLive.Show do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Blood pressure {@blood_pressure.id}
        <:subtitle>This is a blood_pressure record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/blood_pressures"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/blood_pressures/#{@blood_pressure}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit blood_pressure
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Systolic">{@blood_pressure.systolic}</:item>
        <:item title="Diastolic">{@blood_pressure.diastolic}</:item>
        <:item title="Pulse">{@blood_pressure.pulse}</:item>
        <:item title="Measured at">{@blood_pressure.measured_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Blood pressure")
     |> assign(:blood_pressure, BloodPressures.get_blood_pressure!(id))}
  end
end
