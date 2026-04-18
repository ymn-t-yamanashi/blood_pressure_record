defmodule BloodPressureRecordWeb.WeightLive.Index do
  use BloodPressureRecordWeb, :live_view

  alias BloodPressureRecord.Weights
  alias BloodPressureRecordWeb.SharedFormatting

  @per_page 31

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        体重一覧
        <:actions>
          <.button variant="primary" navigate={~p"/weights/new"}>
            <.icon name="hero-plus" /> 体重を追加
          </.button>
        </:actions>
      </.header>

      <.table
        id="weights"
        rows={@streams.weights}
        row_click={fn {_id, weight} -> JS.navigate(~p"/weights/#{weight}") end}
      >
        <:col :let={{_id, weight}} label="測定日時">
          {SharedFormatting.format_datetime(weight.measured_at)}
        </:col>
        <:col :let={{_id, weight}} label="体重(kg)">{format_weight(weight.weight)}</:col>
        <:action :let={{_id, weight}}>
          <div class="sr-only">
            <.link navigate={~p"/weights/#{weight}"}>詳細</.link>
          </div>
          <.link navigate={~p"/weights/#{weight}/edit"}>編集</.link>
        </:action>
        <:action :let={{id, weight}}>
          <.link
            phx-click={JS.push("delete", value: %{id: weight.id}) |> hide("##{id}")}
            data-confirm="この記録を削除しますか？"
          >
            削除
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
              patch={~p"/weights?page=#{@page - 1}"}
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
              patch={~p"/weights?page=#{@page + 1}"}
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
     |> assign(:page_title, "体重一覧")
     |> assign(:page, 1)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 1)
     |> stream(:weights, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = params |> Map.get("page") |> parse_page()
    total_count = Weights.count_weights()
    total_pages = total_pages(total_count)
    current_page = min(page, total_pages)
    weights = list_weights(current_page)

    {:noreply,
     socket
     |> assign(:page, current_page)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> stream(:weights, weights, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    weight = Weights.get_weight!(id)
    {:ok, _} = Weights.delete_weight(weight)
    total_count = max(socket.assigns.total_count - 1, 0)
    total_pages = total_pages(total_count)
    current_page = min(socket.assigns.page, total_pages)
    weights = list_weights(current_page)

    {:noreply,
     socket
     |> assign(:page, current_page)
     |> assign(:total_count, total_count)
     |> assign(:total_pages, total_pages)
     |> stream(:weights, weights, reset: true)}
  end

  defp list_weights(page), do: Weights.list_weights(page: page, per_page: @per_page)

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp total_pages(total_count), do: max(div(total_count + @per_page - 1, @per_page), 1)

  defp format_weight(weight) do
    weight
    |> Decimal.round(1)
    |> Decimal.to_string(:normal)
  end
end
