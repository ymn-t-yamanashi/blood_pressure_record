defmodule BloodPressureRecordWeb.BloodPressureLive.UploadLive do
  use BloodPressureRecordWeb, :live_view

  require Logger

  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecord.Measurements
  alias BloodPressureRecord.Weights
  alias BloodPressureRecordWeb.BloodPressureGraphComponent
  alias Evision, as: Ev
  alias Evision.ColorConversionCodes, as: Evc

  @latest_per_page 15

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    graph_range = "all"
    graph_sync_latest_page = false
    visible_metrics = BloodPressureGraphComponent.default_visible_metrics()
    graph_series_mode = BloodPressureGraphComponent.default_graph_series_mode()
    latest_page = 1

    socket =
      socket
      |> assign(:uploaded_files, [])
      |> assign(:pending_measurement, nil)
      |> assign(:pending_image_data_url, nil)
      |> assign(:confirm_form, to_form(%{"measured_at_date" => ""}, as: :confirm))
      |> assign(:graph_range, graph_range)
      |> assign(:graph_sync_latest_page, graph_sync_latest_page)
      |> assign(:graph_metric_options, BloodPressureGraphComponent.metric_options())
      |> assign(:graph_series_mode, graph_series_mode)
      |> assign(:visible_metrics, visible_metrics)
      |> assign(:graph_visibility_form, to_form(%{"visibility" => visible_metrics}, as: :graph))
      |> assign(
        :graph_series_form,
        to_form(%{"series_mode" => graph_series_mode}, as: :graph_series)
      )
      |> assign(:graph_has_data, false)
      |> refresh_latest_section(latest_page)
      |> maybe_refresh_graph_for_mode()
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("update-confirm", %{"confirm" => confirm_params}, socket) do
    case socket.assigns.pending_measurement do
      nil ->
        {:noreply, socket}

      pending_measurement ->
        updated_measurement =
          pending_measurement
          |> update_confirm_measured_at(confirm_params["measured_at_date"])
          |> update_confirm_metrics(confirm_params)

        {:noreply,
         socket
         |> assign(:pending_measurement, updated_measurement)
         |> assign(:confirm_form, confirm_form(updated_measurement))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("confirm-save", _params, socket) do
    case socket.assigns.pending_measurement do
      nil ->
        {:noreply, put_flash(socket, :error, "先にUploadで読み取りを実行してください")}

      %{type: :blood_pressure} = measurement ->
        save_measurement(socket, :blood_pressure, Map.delete(measurement, :type))

      %{type: :weight} = measurement ->
        save_measurement(socket, :weight, Map.delete(measurement, :type))
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reset-pending", _params, socket) do
    {:noreply, reset_pending(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("change-graph-range", %{"range" => range}, socket)
      when range in ["all", "recent_two_months"] do
    socket =
      case socket.assigns.graph_sync_latest_page do
        true ->
          socket

        false ->
          socket
          |> assign(:graph_range, range)
          |> maybe_refresh_graph_for_mode()
      end

    {:noreply, socket}
  end

  def handle_event("change-graph-range", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("update-graph-visibility", %{"visibility" => visible_metrics}, socket) do
    visible_metrics = BloodPressureGraphComponent.normalize_visible_metrics(visible_metrics)

    {:noreply,
     socket
     |> assign(:visible_metrics, visible_metrics)
     |> assign(:graph_visibility_form, to_form(%{"visibility" => visible_metrics}, as: :graph))
     |> maybe_refresh_graph_for_mode()}
  end

  def handle_event("update-graph-visibility", _params, socket) do
    {:noreply,
     socket
     |> assign(:visible_metrics, [])
     |> assign(:graph_visibility_form, to_form(%{"visibility" => []}, as: :graph))
     |> maybe_refresh_graph_for_mode()}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "update-graph-series-mode",
        %{"graph_series" => %{"series_mode" => mode}},
        socket
      ) do
    graph_series_mode = BloodPressureGraphComponent.normalize_graph_series_mode(mode)

    {:noreply,
     socket
     |> assign(:graph_series_mode, graph_series_mode)
     |> assign(
       :graph_series_form,
       to_form(%{"series_mode" => graph_series_mode}, as: :graph_series)
     )
     |> maybe_refresh_graph_for_mode()}
  end

  def handle_event("update-graph-series-mode", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("toggle-graph-sync-mode", _params, socket) do
    {:noreply,
     socket
     |> assign(:graph_sync_latest_page, !socket.assigns.graph_sync_latest_page)
     |> maybe_refresh_graph_for_mode()}
  end

  @impl Phoenix.LiveView
  def handle_event("change-latest-page", %{"page" => page_value}, socket) do
    with {page, ""} <- Integer.parse(page_value),
         true <- page > 0 do
      {:noreply,
       socket
       |> refresh_latest_section(page)
       |> maybe_refresh_graph_for_mode()}
    else
      _ -> {:noreply, socket}
    end
  end

  def run(file) do
    client = Ollama.init()

    {:ok, ret} =
      Ollama.completion(client,
        model: "gemma3:27b",
        prompt: prompt(),
        images: [get_base64_image(file)]
      )

    response = Map.get(ret, "response", "")

    maybe_log_response(response)

    response
  end

  defp get_base64_image(image_file_path) do
    Ev.imread(image_file_path)
    |> Ev.cvtColor(Evc.cv_COLOR_BGR2GRAY())
    |> then(&Ev.imencode(".jpg", &1))
    |> Base.encode64()
  end

  defp image_data_url(image_file_path) do
    "data:image/jpeg;base64,#{File.read!(image_file_path) |> Base.encode64()}"
  end

  defp measured_at_from_entry(entry) do
    case entry.client_last_modified do
      value when is_integer(value) ->
        value
        |> DateTime.from_unix!(:millisecond)
        |> to_jst_naive()

      _ ->
        DateTime.utc_now()
        |> to_jst_naive()
    end
  end

  defp prompt do
    """
    画像が血圧計か体重計かを判定してください。

    出力は必ず1行のCSVのみで、説明文は禁止です。

    血圧計の場合:
    blood_pressure,最高血圧,最低血圧,脈拍

    体重計の場合:
    weight,体重

    判定不能または読み取り不能の場合:
    error

    体重計画像では中央の大きな表示値だけを読み取り、kgは出力しないでください。
    """
  end

  defp save_measurement(socket, :blood_pressure, params),
    do: persist_measurement(socket, BloodPressures.create_blood_pressure(params))

  defp save_measurement(socket, :weight, params),
    do: persist_measurement(socket, Weights.create_weight(params))

  defp persist_measurement(socket, {:ok, _saved_measurement}) do
    {:noreply,
     socket
     |> reset_pending()
     |> refresh_latest_section(socket.assigns.latest_page)
     |> maybe_refresh_graph_for_mode()}
  end

  defp persist_measurement(socket, {:error, %Ecto.Changeset{}}),
    do: {:noreply, put_flash(socket, :error, "保存に失敗しました")}

  defp parse_measurement_response(""), do: {:error, :parse}
  defp parse_measurement_response("error"), do: {:error, :classification}

  defp parse_measurement_response(response) when is_binary(response) do
    response
    |> String.trim()
    |> String.split(",")
    |> parse_measurement_values()
  end

  defp parse_measurement_values(["blood_pressure", systolic, diastolic, pulse]) do
    with {systolic, ""} <- Integer.parse(String.trim(systolic)),
         {diastolic, ""} <- Integer.parse(String.trim(diastolic)),
         {pulse, ""} <- Integer.parse(String.trim(pulse)) do
      {:ok, %{type: :blood_pressure, systolic: systolic, diastolic: diastolic, pulse: pulse}}
    else
      _ -> {:error, :parse}
    end
  end

  defp parse_measurement_values(["weight", weight_value]) do
    normalized =
      weight_value
      |> String.trim()
      |> String.replace_suffix("kg", "")
      |> String.trim()
      |> normalize_weight_string()

    case Decimal.parse(normalized) do
      {weight, ""} -> {:ok, %{type: :weight, weight: Decimal.round(weight, 1)}}
      _ -> {:error, :parse}
    end
  end

  defp parse_measurement_values(["error"]), do: {:error, :classification}
  defp parse_measurement_values(_values), do: {:error, :parse}

  defp normalize_weight_string(value) do
    if String.contains?(value, ".") do
      value
    else
      value <> ".0"
    end
  end

  defp confirm_form(%{type: :blood_pressure} = measurement) do
    to_form(
      %{
        "measured_at_date" => Date.to_iso8601(NaiveDateTime.to_date(measurement.measured_at)),
        "systolic" => measurement.systolic,
        "diastolic" => measurement.diastolic,
        "pulse" => measurement.pulse
      },
      as: :confirm
    )
  end

  defp confirm_form(%{type: :weight} = measurement) do
    to_form(
      %{
        "measured_at_date" => Date.to_iso8601(NaiveDateTime.to_date(measurement.measured_at)),
        "weight" => format_weight(measurement.weight)
      },
      as: :confirm
    )
  end

  defp to_jst_naive(%DateTime{} = datetime) do
    datetime
    |> DateTime.add(9 * 60 * 60, :second)
    |> DateTime.to_naive()
  end

  defp latest_daily_measurements(page) do
    Measurements.list_daily_measurements(page: page, per_page: @latest_per_page)
  end

  defp latest_averages([]) do
    %{
      systolic: empty_metric(),
      diastolic: empty_metric(),
      pulse: empty_metric(),
      weight: empty_metric()
    }
  end

  defp latest_averages(daily_measurements) do
    systolic_values =
      daily_measurements
      |> Enum.map(fn item -> item.blood_pressure && item.blood_pressure.systolic end)
      |> Enum.reject(&is_nil/1)

    diastolic_values =
      daily_measurements
      |> Enum.map(fn item -> item.blood_pressure && item.blood_pressure.diastolic end)
      |> Enum.reject(&is_nil/1)

    pulse_values =
      daily_measurements
      |> Enum.map(fn item -> item.blood_pressure && item.blood_pressure.pulse end)
      |> Enum.reject(&is_nil/1)

    weight_values =
      daily_measurements
      |> Enum.map(fn item ->
        case item.weight do
          nil -> nil
          weight -> Decimal.to_float(weight.weight)
        end
      end)
      |> Enum.reject(&is_nil/1)

    %{
      systolic: metric_summary(systolic_values, :systolic),
      diastolic: metric_summary(diastolic_values, :diastolic),
      pulse: metric_summary(pulse_values, :pulse),
      weight: neutral_metric_summary(weight_values)
    }
  end

  defp metric_summary([], _metric), do: empty_metric()

  defp metric_summary(values, metric) do
    value = average(values)
    level = risk_level(metric, value)

    %{
      value: value,
      level_text: risk_label(metric, level),
      container_class: risk_container_class(level),
      text_class: risk_text_class(level)
    }
  end

  defp neutral_metric_summary([]), do: empty_metric()

  defp neutral_metric_summary(values) do
    %{
      value: average(values),
      level_text: "記録あり",
      container_class: "border-sky-200 bg-sky-50",
      text_class: "text-sky-700"
    }
  end

  defp average(values) do
    values
    |> Enum.sum()
    |> Kernel./(length(values))
    |> Float.round(1)
  end

  defp refresh_latest_section(socket, requested_page) do
    latest_total_count = Measurements.count_daily_measurements()
    latest_total_pages = total_pages(latest_total_count, @latest_per_page)
    latest_page = min(requested_page, latest_total_pages)
    latest_daily_measurements = latest_daily_measurements(latest_page)

    socket
    |> assign(:latest_page, latest_page)
    |> assign(:latest_total_pages, latest_total_pages)
    |> assign(:latest_total_count, latest_total_count)
    |> assign(:latest_daily_measurements, latest_daily_measurements)
    |> assign(:latest_averages, latest_averages(latest_daily_measurements))
  end

  defp total_pages(0, _per_page), do: 1
  defp total_pages(total_count, per_page), do: div(total_count + per_page - 1, per_page)

  defp graph_measurements_for_mode(%{
         assigns: %{graph_sync_latest_page: true, latest_daily_measurements: measurements}
       }),
       do: measurements

  defp graph_measurements_for_mode(%{assigns: %{graph_range: range}}),
    do: all_daily_measurements_for_range(range)

  defp maybe_refresh_graph_for_mode(socket) do
    daily_measurements = graph_measurements_for_mode(socket)

    has_data =
      BloodPressureGraphComponent.has_data?(daily_measurements, socket.assigns.visible_metrics)

    socket
    |> assign(
      :blood_pressures_image_data,
      BloodPressureGraphComponent.build_image_data(
        daily_measurements,
        width: 1200,
        height: 800,
        visible_metrics: socket.assigns.visible_metrics,
        graph_series_mode: socket.assigns.graph_series_mode
      )
    )
    |> assign(:graph_has_data, has_data)
  end

  defp all_daily_measurements_for_range("all"),
    do: Measurements.list_daily_measurements_for_graph()

  defp all_daily_measurements_for_range("recent_two_months") do
    cutoff = Date.add(Date.utc_today(), -60)

    Measurements.list_daily_measurements_for_graph()
    |> Enum.filter(&(Date.compare(&1.date, cutoff) != :lt))
  end

  defp empty_metric do
    %{
      value: nil,
      level_text: "データなし",
      container_class: "border-zinc-200 bg-zinc-50",
      text_class: "text-zinc-500"
    }
  end

  defp risk_level(:systolic, value) do
    cond do
      value >= 135 -> :danger
      value >= 125 -> :warning
      value >= 115 -> :caution
      true -> :normal
    end
  end

  defp risk_level(:diastolic, value) do
    cond do
      value >= 85 -> :danger
      value >= 75 -> :warning
      true -> :normal
    end
  end

  defp risk_level(:pulse, value) do
    cond do
      value >= 120 -> :danger
      value >= 100 -> :warning
      value >= 90 -> :caution
      value >= 60 -> :normal
      true -> :caution
    end
  end

  defp risk_label(metric, level) when metric in [:systolic, :diastolic] do
    case level do
      :normal -> "正常血圧"
      :caution -> "正常高値血圧"
      :warning -> "高値血圧"
      :danger -> "高血圧"
    end
  end

  defp risk_label(:pulse, :normal), do: "正常"
  defp risk_label(:pulse, :caution), do: "注意"
  defp risk_label(:pulse, :warning), do: "警戒"
  defp risk_label(:pulse, :danger), do: "危険"

  defp risk_container_class(:normal), do: "border-emerald-200 bg-emerald-50"
  defp risk_container_class(:caution), do: "border-lime-200 bg-lime-50"
  defp risk_container_class(:warning), do: "border-orange-400 bg-orange-200"
  defp risk_container_class(:danger), do: "border-rose-500 bg-rose-300"

  defp risk_text_class(:normal), do: "text-emerald-700"
  defp risk_text_class(:caution), do: "text-lime-700"
  defp risk_text_class(:warning), do: "text-orange-700"
  defp risk_text_class(:danger), do: "text-rose-700"

  def risk_cell_class(_metric, value) when value in [nil, false], do: "bg-white"

  def risk_cell_class(metric, value) do
    risk_level(metric, value)
    |> risk_container_class()
  end

  def measurement_date_cell_class(%Date{} = date) do
    case Date.day_of_week(date) do
      6 -> "bg-sky-100"
      7 -> "bg-pink-100"
      _ -> "bg-zinc-50"
    end
  end

  def format_metric_value(nil), do: "-"

  def format_metric_value(value) when is_float(value),
    do: :erlang.float_to_binary(value, decimals: 1)

  def format_metric_value(value), do: value

  def format_weight(nil), do: "-"

  def format_weight(%Decimal{} = weight) do
    weight
    |> Decimal.round(1)
    |> Decimal.to_string(:normal)
  end

  defp reset_pending(socket) do
    socket
    |> assign(:pending_measurement, nil)
    |> assign(:pending_image_data_url, nil)
    |> assign(:confirm_form, to_form(%{"measured_at_date" => ""}, as: :confirm))
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp handle_progress(:avatar, entry, socket) do
    case entry.done? do
      true ->
        upload_result =
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            {:ok,
             %{
               response: run(path),
               image_data_url: image_data_url(path),
               measured_at: measured_at_from_entry(entry)
             }}
          end)

        preview_image = upload_result && upload_result.image_data_url
        measured_at = upload_result && upload_result.measured_at

        socket =
          case parse_measurement_response(upload_result && upload_result.response) do
            {:ok, measurement_params} ->
              pending_measurement = Map.put(measurement_params, :measured_at, measured_at)

              socket
              |> assign(:pending_measurement, pending_measurement)
              |> assign(:pending_image_data_url, preview_image)
              |> assign(:confirm_form, confirm_form(pending_measurement))

            {:error, :classification} ->
              put_flash(socket, :error, "血圧か体重かを判定できませんでした")

            {:error, :parse} ->
              put_flash(socket, :error, "画像から数値を読み取れませんでした")
          end

        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  defp maybe_log_response(response) do
    endpoint_config =
      Application.get_env(:blood_pressure_record, BloodPressureRecordWeb.Endpoint, [])

    case Keyword.get(endpoint_config, :code_reloader, false) do
      true -> Logger.debug("Ollama response: #{inspect(response)}")
      false -> :ok
    end
  end

  defp update_confirm_measured_at(%{measured_at: measured_at} = measurement, date_value) do
    case Date.from_iso8601(date_value || "") do
      {:ok, date} ->
        Map.put(
          measurement,
          :measured_at,
          NaiveDateTime.new!(date, NaiveDateTime.to_time(measured_at))
        )

      _ ->
        measurement
    end
  end

  defp update_confirm_metrics(%{type: :blood_pressure} = measurement, confirm_params) do
    measurement
    |> maybe_put_integer(:systolic, confirm_params["systolic"])
    |> maybe_put_integer(:diastolic, confirm_params["diastolic"])
    |> maybe_put_integer(:pulse, confirm_params["pulse"])
  end

  defp update_confirm_metrics(%{type: :weight} = measurement, confirm_params) do
    case parse_weight(confirm_params["weight"]) do
      {:ok, weight} -> Map.put(measurement, :weight, weight)
      :error -> measurement
    end
  end

  defp maybe_put_integer(measurement, _key, nil), do: measurement

  defp maybe_put_integer(measurement, key, value) do
    case Integer.parse(to_string(value)) do
      {parsed, ""} -> Map.put(measurement, key, parsed)
      _ -> measurement
    end
  end

  defp parse_weight(nil), do: :error

  defp parse_weight(value) do
    normalized =
      value
      |> to_string()
      |> String.trim()
      |> String.replace_suffix("kg", "")
      |> String.trim()
      |> normalize_weight_string()

    case Decimal.parse(normalized) do
      {weight, ""} -> {:ok, Decimal.round(weight, 1)}
      _ -> :error
    end
  end
end
