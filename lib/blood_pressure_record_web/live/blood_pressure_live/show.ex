defmodule BloodPressureRecordWeb.BloodPressureLive.Show do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecordWeb.SharedFormatting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        血圧詳細
        <:subtitle>血圧の記録を確認します。</:subtitle>
        <:actions>
          <.button navigate={~p"/blood_pressures"}>
            <.icon name="hero-arrow-left" /> 戻る
          </.button>
          <.button
            variant="primary"
            navigate={~p"/blood_pressures/#{@blood_pressure}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> 編集
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="最高血圧">{@blood_pressure.systolic}</:item>
        <:item title="最低血圧">{@blood_pressure.diastolic}</:item>
        <:item title="脈拍">{@blood_pressure.pulse}</:item>
        <:item title="測定日時">
          {SharedFormatting.format_datetime(@blood_pressure.measured_at)}
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "血圧詳細")
     |> assign(:blood_pressure, BloodPressures.get_blood_pressure!(id))}
  end
end
