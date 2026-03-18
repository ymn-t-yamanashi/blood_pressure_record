defmodule BloodPressureRecordWeb.BloodPressureLive.Graph do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecordWeb.BloodPressureGraphComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.blood_pressure_graph png={@blood_pressures_png} />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Blood pressures")
     |> assign(:blood_pressures_png, blood_pressures_png())}
  end

  defp blood_pressures_png() do
    BloodPressures.list_blood_pressures()
    |> BloodPressureGraphComponent.build_png()
  end
end
