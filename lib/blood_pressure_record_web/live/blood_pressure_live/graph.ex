defmodule BloodPressureRecordWeb.BloodPressureLive.Graph do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  alias BloodPressureRecordWeb.BloodPressureGraphComponent

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="mx-auto flex w-full max-w-5xl flex-col gap-6 px-4 py-8 sm:px-6 lg:px-8">
        <div class="flex flex-col gap-2">
          <p class="text-xs font-semibold uppercase tracking-[0.28em] text-sky-600">Graph</p>
          <h1 class="text-3xl font-semibold tracking-tight text-slate-900">血圧推移グラフ</h1>
          <p class="text-sm text-slate-600">表示する系列を切り替えて、推移を見比べられます。</p>
        </div>

        <.form for={@form} id="graph-visibility-form" phx-change="update_visibility">
          <fieldset class="rounded-3xl border border-slate-200 bg-white/90 p-4 shadow-sm">
            <legend class="px-2 text-sm font-medium text-slate-700">表示項目</legend>
            <div class="mt-3 grid gap-3 sm:grid-cols-3">
              <label
                :for={{metric, label} <- @metric_options}
                for={"visibility-#{metric}"}
                class="flex cursor-pointer items-center justify-between rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700 transition hover:border-sky-300 hover:bg-sky-50"
              >
                <span>{label}</span>
                <input
                  id={"visibility-#{metric}"}
                  type="checkbox"
                  name="visibility[]"
                  value={metric}
                  checked={metric in @visible_metrics}
                  class="h-4 w-4 rounded border-slate-300 text-sky-600 focus:ring-sky-500"
                />
              </label>
            </div>
          </fieldset>
        </.form>

        <.blood_pressure_graph
          png={@blood_pressures_png}
          class="w-full rounded-3xl border border-slate-200 bg-white p-3 shadow-sm"
        />
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    visible_metrics = BloodPressureGraphComponent.default_visible_metrics()

    {:ok,
     socket
     |> assign(:page_title, "Listing Blood pressures")
     |> assign(:metric_options, BloodPressureGraphComponent.metric_options())
     |> assign(:visible_metrics, visible_metrics)
     |> assign(:form, to_form(%{"visibility" => visible_metrics}, as: :graph))
     |> assign(:blood_pressures_png, blood_pressures_png(visible_metrics))}
  end

  @impl true
  def handle_event("update_visibility", %{"visibility" => visible_metrics}, socket) do
    visible_metrics = BloodPressureGraphComponent.normalize_visible_metrics(visible_metrics)

    {:noreply,
     socket
     |> assign(:visible_metrics, visible_metrics)
     |> assign(:form, to_form(%{"visibility" => visible_metrics}, as: :graph))
     |> assign(:blood_pressures_png, blood_pressures_png(visible_metrics))}
  end

  def handle_event("update_visibility", _params, socket) do
    visible_metrics = []

    {:noreply,
     socket
     |> assign(:visible_metrics, visible_metrics)
     |> assign(:form, to_form(%{"visibility" => visible_metrics}, as: :graph))
     |> assign(:blood_pressures_png, blood_pressures_png(visible_metrics))}
  end

  defp blood_pressures_png(visible_metrics) do
    BloodPressures.list_blood_pressures()
    |> BloodPressureGraphComponent.build_png(visible_metrics: visible_metrics)
  end
end
