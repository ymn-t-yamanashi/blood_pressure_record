defmodule BloodPressureRecordWeb.WeightLive.Show do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.Weights
  alias BloodPressureRecordWeb.SharedFormatting

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        体重詳細
        <:subtitle>体重の記録を確認します。</:subtitle>
        <:actions>
          <.button navigate={~p"/weights"}>
            <.icon name="hero-arrow-left" /> 戻る
          </.button>
          <.button variant="primary" navigate={~p"/weights/#{@weight}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> 編集
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="体重">{format_weight(@weight.weight)} kg</:item>
        <:item title="測定日時">{SharedFormatting.format_datetime(@weight.measured_at)}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "体重詳細")
     |> assign(:weight, Weights.get_weight!(id))}
  end

  defp format_weight(weight) do
    weight
    |> Decimal.round(1)
    |> Decimal.to_string(:normal)
  end
end
