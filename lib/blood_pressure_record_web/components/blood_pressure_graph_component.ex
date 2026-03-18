defmodule BloodPressureRecordWeb.BloodPressureGraphComponent do
  use Phoenix.Component

  alias VegaLite, as: Vl
  alias VegaLite.Convert, as: VlConvert

  attr :png, :string, required: true
  attr :class, :string, default: nil

  def blood_pressure_graph(assigns) do
    ~H"""
    <img src={"data:image/png;base64,#{@png}"} class={@class} />
    """
  end

  def build_png(blood_pressures, opts \\ []) do
    width = Keyword.get(opts, :width, 600)
    height = Keyword.get(opts, :height, 400)

    blood_pressures
    |> Enum.flat_map(&to_graph_data/1)
    |> draw_graph(width, height)
  end

  defp to_graph_data(data) do
    date = NaiveDateTime.to_date(data.measured_at)

    [
      %{date: date, type: "最高血圧", value: data.systolic},
      %{date: date, type: "最低血圧", value: data.diastolic},
      %{date: date, type: "脈拍", value: data.pulse}
    ]
  end

  defp draw_graph(data, width, height) do
    Vl.new(width: width, height: height)
    |> Vl.data_from_values(data)
    |> Vl.mark(:line, point: true)
    |> Vl.encode_field(:x, "date",
      type: :temporal,
      title: "測定日",
      axis: [
        format: "%Y/%m/%d",
        tickCount: "day"
      ]
    )
    |> Vl.encode_field(:y, "value", type: :quantitative, title: "値 (mmHg または 拍/分)")
    |> Vl.encode_field(:color, "type", type: :nominal, title: "測定項目")
    |> VlConvert.to_png()
    |> Base.encode64()
  end
end
