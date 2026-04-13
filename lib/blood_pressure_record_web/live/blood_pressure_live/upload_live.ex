defmodule BloodPressureRecordWeb.BloodPressureLive.UploadLive do
  use BloodPressureRecordWeb, :live_view
  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecordWeb.BloodPressureGraphComponent
  alias Evision, as: Ev
  alias Evision.ColorConversionCodes, as: Evc

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    graph_range = "all"
    latest_blood_pressures = latest_blood_pressures()

    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:pending_blood_pressure, nil)
     |> assign(:pending_image_data_url, nil)
     |> assign(:confirm_form, to_form(%{"measured_at_date" => ""}, as: :confirm))
     |> assign(:graph_range, graph_range)
     |> assign(:latest_blood_pressures, latest_blood_pressures)
     |> assign(:latest_averages, latest_averages(latest_blood_pressures))
     |> assign(:blood_pressures_png, blood_pressures_png(graph_range))
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg),
       max_entries: 1,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "update-measured-at",
        %{"confirm" => %{"measured_at_date" => date_value}},
        socket
      ) do
    case socket.assigns.pending_blood_pressure do
      %{measured_at: measured_at} = pending_blood_pressure ->
        case Date.from_iso8601(date_value) do
          {:ok, date} ->
            updated_measured_at = NaiveDateTime.new!(date, NaiveDateTime.to_time(measured_at))

            updated_blood_pressure =
              Map.put(pending_blood_pressure, :measured_at, updated_measured_at)

            {:noreply,
             socket
             |> assign(:pending_blood_pressure, updated_blood_pressure)
             |> assign(:confirm_form, measured_at_form(updated_measured_at))}

          _ ->
            {:noreply, assign(socket, :confirm_form, measured_at_form(measured_at))}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("confirm-save", _params, socket) do
    case socket.assigns.pending_blood_pressure do
      nil ->
        {:noreply, put_flash(socket, :error, "先にUploadで読み取りを実行してください")}

      blood_pressure_params ->
        save_blood_pressure(socket, blood_pressure_params)
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reset-pending", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_blood_pressure, nil)
     |> assign(:pending_image_data_url, nil)
     |> assign(:confirm_form, to_form(%{"measured_at_date" => ""}, as: :confirm))}
  end

  @impl Phoenix.LiveView
  def handle_event("change-graph-range", %{"range" => range}, socket)
      when range in ["all", "recent_two_months"] do
    {:noreply,
     socket
     |> assign(:graph_range, range)
     |> assign(:blood_pressures_png, blood_pressures_png(range))}
  end

  def handle_event("change-graph-range", _params, socket), do: {:noreply, socket}

  def run(file) do
    client = Ollama.init()

    {:ok, ret} =
      Ollama.completion(client,
        model: "gemma3:27b",
        prompt: prompt(),
        images: [get_base64_image(file)]
      )

    ret
    |> Map.get("response")
    |> String.split(",")
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

  defp prompt() do
    """
    次の数値のみ取得してください
    - 最高血圧
    - 最低血圧
    - 脈拍

    出力はCSV形式で
    フォーマット例
    120,70,80
    """
  end

  defp save_blood_pressure(socket, blood_pressure_params) do
    case BloodPressures.create_blood_pressure(blood_pressure_params) do
      {:ok, _} ->
        latest_blood_pressures = latest_blood_pressures()

        {:noreply,
         socket
         |> put_flash(:info, "Blood pressure created successfully")
         |> assign(:pending_blood_pressure, nil)
         |> assign(:pending_image_data_url, nil)
         |> assign(:confirm_form, to_form(%{"measured_at_date" => ""}, as: :confirm))
         |> assign(:latest_blood_pressures, latest_blood_pressures)
         |> assign(:latest_averages, latest_averages(latest_blood_pressures))
         |> assign(:blood_pressures_png, blood_pressures_png(socket.assigns.graph_range))}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "保存に失敗しました")}
    end
  end

  defp parse_blood_pressure(nil), do: :error

  defp parse_blood_pressure(values) when is_list(values) do
    with systolic when not is_nil(systolic) <- Enum.at(values, 0),
         diastolic when not is_nil(diastolic) <- Enum.at(values, 1),
         pulse when not is_nil(pulse) <- Enum.at(values, 2),
         {systolic, ""} <- Integer.parse(String.trim(systolic)),
         {diastolic, ""} <- Integer.parse(String.trim(diastolic)),
         {pulse, ""} <- Integer.parse(String.trim(pulse)) do
      {:ok, %{systolic: systolic, diastolic: diastolic, pulse: pulse}}
    else
      _ -> :error
    end
  end

  defp parse_blood_pressure(_values), do: :error

  defp measured_at_form(%NaiveDateTime{} = measured_at) do
    to_form(%{"measured_at_date" => Date.to_iso8601(NaiveDateTime.to_date(measured_at))},
      as: :confirm
    )
  end

  defp to_jst_naive(%DateTime{} = datetime) do
    datetime
    |> DateTime.add(9 * 60 * 60, :second)
    |> DateTime.to_naive()
  end

  defp latest_blood_pressures do
    BloodPressures.list_blood_pressures(page: 1, per_page: 15)
  end

  defp latest_averages([]) do
    %{
      systolic: empty_metric(),
      diastolic: empty_metric(),
      pulse: empty_metric()
    }
  end

  defp latest_averages(blood_pressures) do
    count = length(blood_pressures)

    %{
      systolic:
        blood_pressures
        |> Enum.map(& &1.systolic)
        |> average(count)
        |> metric_summary(:systolic),
      diastolic:
        blood_pressures
        |> Enum.map(& &1.diastolic)
        |> average(count)
        |> metric_summary(:diastolic),
      pulse:
        blood_pressures
        |> Enum.map(& &1.pulse)
        |> average(count)
        |> metric_summary(:pulse)
    }
  end

  defp average(values, count) do
    values
    |> Enum.sum()
    |> Kernel./(count)
    |> Float.round(1)
  end

  defp empty_metric do
    %{
      value: nil,
      level_text: "データなし",
      container_class: "border-zinc-200 bg-zinc-50",
      text_class: "text-zinc-500"
    }
  end

  defp metric_summary(value, metric) do
    level = risk_level(metric, value)

    %{
      value: value,
      level_text: risk_label(level),
      container_class: risk_container_class(level),
      text_class: risk_text_class(level)
    }
  end

  defp risk_level(:systolic, value) do
    cond do
      value >= 160 -> :danger
      value >= 140 -> :warning
      value >= 120 -> :caution
      true -> :normal
    end
  end

  defp risk_level(:diastolic, value) do
    cond do
      value >= 100 -> :danger
      value >= 90 -> :warning
      value >= 80 -> :caution
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

  defp risk_label(:normal), do: "正常"
  defp risk_label(:caution), do: "注意"
  defp risk_label(:warning), do: "警戒"
  defp risk_label(:danger), do: "危険"

  defp risk_container_class(:normal), do: "border-emerald-300 bg-emerald-50"
  defp risk_container_class(:caution), do: "border-amber-300 bg-amber-50"
  defp risk_container_class(:warning), do: "border-orange-300 bg-orange-50"
  defp risk_container_class(:danger), do: "border-rose-300 bg-rose-50"

  defp risk_text_class(:normal), do: "text-emerald-700"
  defp risk_text_class(:caution), do: "text-amber-700"
  defp risk_text_class(:warning), do: "text-orange-700"
  defp risk_text_class(:danger), do: "text-rose-700"

  defp blood_pressures_png(range) do
    BloodPressures.list_blood_pressures()
    |> filter_for_graph_range(range)
    |> BloodPressureGraphComponent.build_png(width: 1200, height: 800)
  end

  defp filter_for_graph_range(blood_pressures, "all"), do: blood_pressures

  defp filter_for_graph_range(blood_pressures, "recent_two_months") do
    cutoff = Date.add(Date.utc_today(), -60)

    Enum.filter(blood_pressures, fn blood_pressure ->
      blood_pressure.measured_at
      |> NaiveDateTime.to_date()
      |> Date.compare(cutoff)
      |> Kernel.!=(:lt)
    end)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp handle_progress(:avatar, entry, socket) do
    if entry.done? do
      upload_result =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          {:ok,
           %{
             values: run(path),
             image_data_url: image_data_url(path),
             measured_at: measured_at_from_entry(entry)
           }}
        end)

      parsed_values = upload_result && upload_result.values
      preview_image = upload_result && upload_result.image_data_url
      measured_at = upload_result && upload_result.measured_at

      socket =
        case parse_blood_pressure(parsed_values) do
          {:ok, blood_pressure_params} ->
            pending_blood_pressure = Map.put(blood_pressure_params, :measured_at, measured_at)

            socket
            |> assign(:pending_blood_pressure, pending_blood_pressure)
            |> assign(:pending_image_data_url, preview_image)
            |> assign(:confirm_form, measured_at_form(pending_blood_pressure.measured_at))

          :error ->
            put_flash(socket, :error, "画像から数値を読み取れませんでした")
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
end
