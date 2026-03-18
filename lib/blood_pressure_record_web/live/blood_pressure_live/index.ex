defmodule BloodPressureRecordWeb.BloodPressureLive.Index do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.BloodPressures
  @per_page 31

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Blood pressures
        <:actions>
          <.button variant="primary" navigate={~p"/up"}>
            <.icon name="hero-plus" /> Up Blood pressure
          </.button>
          <.button variant="primary" navigate={~p"/blood_pressures/new"}>
            <.icon name="hero-plus" /> New Blood pressure
          </.button>
        </:actions>
      </.header>

      <.table
        id="blood_pressures"
        rows={@streams.blood_pressures}
        row_click={
          fn {_id, blood_pressure} -> JS.navigate(~p"/blood_pressures/#{blood_pressure}") end
        }
      >
        <:col :let={{_id, blood_pressure}} label="Measured at">
          {format_measured_at(blood_pressure.measured_at)}
        </:col>
        <:col :let={{_id, blood_pressure}} label="Systolic">{blood_pressure.systolic}</:col>
        <:col :let={{_id, blood_pressure}} label="Diastolic">{blood_pressure.diastolic}</:col>
        <:col :let={{_id, blood_pressure}} label="Pulse">{blood_pressure.pulse}</:col>
        <:action :let={{_id, blood_pressure}}>
          <div class="sr-only">
            <.link navigate={~p"/blood_pressures/#{blood_pressure}"}>Show</.link>
          </div>
          <.link navigate={~p"/blood_pressures/#{blood_pressure}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, blood_pressure}}>
          <.link
            phx-click={JS.push("delete", value: %{id: blood_pressure.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <div class="mt-6 flex items-center justify-between gap-4">
        <p class="text-sm text-zinc-600">
          Page {@page} / {@total_pages} ({@total_count} records)
        </p>

        <div class="flex items-center gap-2">
          <%= if @page > 1 do %>
            <.link
              patch={~p"/blood_pressures?page=#{@page - 1}"}
              class="rounded-md border border-zinc-300 px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-100"
            >
              Previous
            </.link>
          <% else %>
            <span class="rounded-md border border-zinc-200 px-3 py-2 text-sm font-medium text-zinc-400">
              Previous
            </span>
          <% end %>

          <%= if @page < @total_pages do %>
            <.link
              patch={~p"/blood_pressures?page=#{@page + 1}"}
              class="rounded-md border border-zinc-300 px-3 py-2 text-sm font-medium text-zinc-700 transition hover:bg-zinc-100"
            >
              Next
            </.link>
          <% else %>
            <span class="rounded-md border border-zinc-200 px-3 py-2 text-sm font-medium text-zinc-400">
              Next
            </span>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Blood pressures")
     |> assign(:page, 1)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 1)
     |> stream(:blood_pressures, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = params |> Map.get("page") |> parse_page()
    total_count = BloodPressures.count_blood_pressures()
    total_pages = total_pages(total_count)
    current_page = min(page, total_pages)
    blood_pressures = list_blood_pressures(current_page)

    {:noreply,
     socket
     |> assign(:page, current_page)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> stream(:blood_pressures, blood_pressures, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    blood_pressure = BloodPressures.get_blood_pressure!(id)
    {:ok, _} = BloodPressures.delete_blood_pressure(blood_pressure)
    total_count = max(socket.assigns.total_count - 1, 0)
    total_pages = total_pages(total_count)
    current_page = min(socket.assigns.page, total_pages)
    blood_pressures = list_blood_pressures(current_page)

    {:noreply,
     socket
     |> assign(:page, current_page)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> stream(:blood_pressures, blood_pressures, reset: true)}
  end

  defp list_blood_pressures(page) do
    BloodPressures.list_blood_pressures(page: page, per_page: @per_page)
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp total_pages(total_count) do
    max(div(total_count + @per_page - 1, @per_page), 1)
  end

  defp format_measured_at(%NaiveDateTime{} = measured_at) do
    Calendar.strftime(measured_at, "%Y/%m/%d")
  end
end
