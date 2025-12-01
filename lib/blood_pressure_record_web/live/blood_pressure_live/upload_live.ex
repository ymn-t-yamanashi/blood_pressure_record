defmodule BloodPressureRecordWeb.BloodPressureLive.UploadLive do
  use BloodPressureRecordWeb, :live_view
  alias BloodPressureRecord.BloodPressures
  alias Evision, as: Ev
  alias Evision.ColorConversionCodes, as: Evc

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg), max_entries: 1)}
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
  def handle_event("save", _params, socket) do
    data =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        {:ok, run(path)}
      end)
      |> List.first()

    systolic = Enum.at(data, 0) |> String.to_integer()
    diastolic = Enum.at(data, 1) |> String.to_integer()
    pulse = Enum.at(data, 2) |> String.to_integer()
    measured_at = NaiveDateTime.utc_now()

    save_blood_pressure(socket, %{
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      measured_at: measured_at
    })

  end

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
        {:noreply,
         socket
         |> put_flash(:info, "Blood pressure created successfully")
         |> push_navigate(to: "/blood_pressures")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
