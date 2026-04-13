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
    month_first_dates = month_first_dates(data)

    line_chart =
      Vl.new()
      |> Vl.data_from_values(data)
      |> Vl.mark(:line, point: true)
      |> Vl.encode_field(:x, "date",
        type: :temporal,
        title: "測定日",
        axis: [
          format: "%Y/%m/%d",
          values: month_first_dates,
          grid: true,
          grid_color: "#d4d4d8",
          grid_opacity: 0.5
        ]
      )
      |> Vl.encode_field(:y, "value",
        type: :quantitative,
        title: "値 (mmHg または 拍/分)",
        scale: [domain_min: 50]
      )
      |> Vl.encode_field(:color, "type", type: :nominal, title: "測定項目")

    systolic_threshold =
      Vl.new()
      |> Vl.data_from_values([%{threshold: 120}])
      |> Vl.mark(:rule, color: "#facc15", stroke_width: 2, stroke_dash: [10, 6])
      |> Vl.encode_field(:y, "threshold", type: :quantitative, scale: [domain_min: 50])

    diastolic_threshold =
      Vl.new()
      |> Vl.data_from_values([%{threshold: 70}])
      |> Vl.mark(:rule, color: "#facc15", stroke_width: 2, stroke_dash: [10, 6])
      |> Vl.encode_field(:y, "threshold", type: :quantitative, scale: [domain_min: 50])

    Vl.new(width: width, height: height)
    |> Vl.layers([line_chart, systolic_threshold, diastolic_threshold])
    |> VlConvert.to_png()
    |> Base.encode64()
  end

  defp month_first_dates([]), do: []

  defp month_first_dates(data) do
    dates = Enum.map(data, & &1.date)
    {min_date, max_date} = Enum.min_max_by(dates, &Date.to_gregorian_days/1)

    first_month = %Date{year: min_date.year, month: min_date.month, day: 1}
    last_month = %Date{year: max_date.year, month: max_date.month, day: 1}

    Stream.unfold(first_month, fn current ->
      if Date.compare(current, last_month) == :gt do
        nil
      else
        next_month =
          if current.month == 12 do
            %Date{year: current.year + 1, month: 1, day: 1}
          else
            %{current | month: current.month + 1}
          end

        {current, next_month}
      end
    end)
    |> Enum.to_list()
  end
end
