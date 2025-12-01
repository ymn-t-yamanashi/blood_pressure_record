defmodule BloodPressureRecordWeb.BloodPressureLive.Graph do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  alias VegaLite, as: Vl
  alias VegaLite.Convert, as: VlConvert

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <img src={"data:image/png;base64,#{@blood_pressures_png}"}>
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
    |> Enum.map(&convert_data/1)
    |> List.flatten()
    |> draw_graph()
  end

  def convert_data(data) do
    date = NaiveDateTime.to_date(data.measured_at)

    [
      %{date: date, type: "最高血圧", value: data.systolic},
      %{date: date, type: "最低血圧", value: data.diastolic},
      %{date: date, type: "脈拍", value: data.pulse}
    ]
  end

  def draw_graph(data) do
    # 1. グラフ化するデータの定義 (ロングフォーマット)
    # 日付(date), 測定項目(type), 値(value) を持たせる

    # 2. Vega-Liteの定義
    Vl.new(width: 600, height: 400)
    # データをグラフに渡す
    |> Vl.data_from_values(data)
    # マークは折れ線のみを使用
    # point: trueでデータ点も表示し、見やすくする
    |> Vl.mark(:line, point: true)

    # X軸のエンコーディング: 日付は時系列データとして扱う
    |> Vl.encode_field(:x, "date",
      type: :temporal,
      title: "測定日",
      axis: [
        format: "%Y/%m/%d",
        tickCount: "day"
      ]
    )
    # Y軸のエンコーディング: 値をマッピング
    |> Vl.encode_field(:y, "value", type: :quantitative, title: "値 (mmHg または 拍/分)")
    # 色のエンコーディング: type（測定項目）ごとに色分けして、線を分ける
    |> Vl.encode_field(:color, "type", type: :nominal, title: "測定項目")

    # グラフの書き出し
    |> VlConvert.to_png()
    |> Base.encode64()
  end
end
