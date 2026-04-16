defmodule BloodPressureRecordWeb.BloodPressureGraphComponent do
  use Phoenix.Component

  alias VegaLite, as: Vl
  alias VegaLite.Convert, as: VlConvert

  @metric_options [
    {"systolic", "最高血圧"},
    {"diastolic", "最低血圧"},
    {"pulse", "脈拍"}
  ]
  @default_visible_metrics ["systolic", "diastolic"]
  @metric_thresholds %{
    "systolic" => [
      %{value: 114, color: "#10b981"},
      %{value: 115, color: "#f59e0b"},
      %{value: 125, color: "#f97316"},
      %{value: 135, color: "#f43f5e"}
    ],
    "diastolic" => [
      %{value: 74, color: "#10b981"},
      %{value: 75, color: "#f97316"},
      %{value: 85, color: "#f43f5e"}
    ]
  }

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
    visible_metrics = Keyword.get(opts, :visible_metrics, @default_visible_metrics)

    blood_pressures
    |> Enum.flat_map(&to_graph_data/1)
    |> Enum.filter(&visible_metric?(&1.type, visible_metrics))
    |> draw_graph(width, height)
  end

  def metric_options, do: @metric_options
  def default_visible_metrics, do: @default_visible_metrics

  def normalize_visible_metrics(metrics) when is_list(metrics) do
    valid_metrics = Enum.map(@metric_options, fn {metric, _label} -> metric end)

    metrics
    |> Enum.uniq()
    |> Enum.filter(&(&1 in valid_metrics))
  end

  def normalize_visible_metrics(_metrics), do: []

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
    averages = fifteen_day_averages(data)
    thresholds = threshold_lines(data)

    line_chart =
      Vl.new()
      |> Vl.data_from_values(data)
      |> Vl.mark(:line, point: [size: 20], stroke_dash: [2, 2])
      |> Vl.encode_field(:x, "date",
        type: :temporal,
        title: "測定日",
        axis: [
          format: "%Y/%m/%d",
          label_font_size: 32,
          title_font_size: 40,
          values: month_first_dates,
          grid: true,
          grid_color: "#52525b",
          grid_opacity: 1.0
        ]
      )
      |> Vl.encode_field(:y, "value",
        type: :quantitative,
        title: "値 (mmHg または 拍/分)",
        scale: [domain_min: 50],
        axis: [label_font_size: 32, title_font_size: 40]
      )
      |> Vl.encode_field(:color, "type", type: :nominal, title: "測定項目")

    threshold_lines =
      Vl.new()
      |> Vl.data_from_values(thresholds)
      |> Vl.mark(:rule, stroke_width: 2, stroke_dash: [10, 6], opacity: 0.75)
      |> Vl.encode_field(:y, "threshold", type: :quantitative, scale: [domain_min: 50])
      |> Vl.encode_field(:color, "color",
        type: :nominal,
        legend: nil,
        scale: nil
      )

    average_lines =
      Vl.new()
      |> Vl.data_from_values(averages)
      |> Vl.mark(:line, stroke_width: 2, opacity: 0.85, point: [size: 20])
      |> Vl.encode_field(:x, "date", type: :temporal)
      |> Vl.encode_field(:y, "value", type: :quantitative, scale: [domain_min: 50])
      |> Vl.encode_field(:color, "type", type: :nominal, title: "測定項目")

    Vl.new(width: width, height: height)
    |> Vl.config(
      legend: [
        label_font_size: 32,
        title_font_size: 40,
        symbol_size: 440,
        padding: 16
      ],
      axis: [label_limit: 240],
      style: [guide_title: [font_size: 40], guide_label: [font_size: 32]],
      view: [stroke: :transparent]
    )
    |> Vl.layers([line_chart, average_lines, threshold_lines])
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

  defp fifteen_day_averages([]), do: []

  defp fifteen_day_averages(data) do
    dates = Enum.map(data, & &1.date)
    min_date = Enum.min_by(dates, &Date.to_gregorian_days/1)
    max_date = Enum.max_by(dates, &Date.to_gregorian_days/1)

    data
    |> Enum.group_by(fn item -> {item.type, fifteen_day_bucket(item.date, min_date)} end)
    |> Enum.map(fn {{type, bucket}, items} ->
      bucket_start = Date.add(min_date, bucket * 15)

      avg =
        items
        |> Enum.map(& &1.value)
        |> then(&(Enum.sum(&1) / length(&1)))

      %{date: bucket_start, type: type, value: avg}
    end)
    |> Enum.group_by(& &1.type)
    |> Enum.flat_map(fn {_type, points} ->
      sorted_points = Enum.sort_by(points, &Date.to_gregorian_days(&1.date))
      last_point = List.last(sorted_points)

      if Date.compare(last_point.date, max_date) == :lt do
        sorted_points ++ [%{last_point | date: max_date}]
      else
        sorted_points
      end
    end)
    |> Enum.sort_by(fn item -> {item.type, Date.to_gregorian_days(item.date)} end)
  end

  defp fifteen_day_bucket(date, min_date), do: div(Date.diff(date, min_date), 15)

  defp threshold_lines(data) do
    data
    |> Enum.map(&metric_key/1)
    |> Enum.uniq()
    |> Enum.flat_map(fn metric ->
      Map.get(@metric_thresholds, metric, [])
      |> Enum.map(fn %{value: value, color: color} ->
        %{threshold: value, color: color}
      end)
    end)
  end

  defp metric_key(%{type: "最高血圧"}), do: "systolic"
  defp metric_key(%{type: "最低血圧"}), do: "diastolic"
  defp metric_key(%{type: "脈拍"}), do: "pulse"

  defp visible_metric?("最高血圧", visible_metrics), do: "systolic" in visible_metrics
  defp visible_metric?("最低血圧", visible_metrics), do: "diastolic" in visible_metrics
  defp visible_metric?("脈拍", visible_metrics), do: "pulse" in visible_metrics
end
