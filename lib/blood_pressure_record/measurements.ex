defmodule BloodPressureRecord.Measurements do
  @moduledoc """
  Daily measurement aggregation for blood pressures and weights.
  """

  import Ecto.Query, warn: false

  alias BloodPressureRecord.BloodPressures.BloodPressure
  alias BloodPressureRecord.Repo
  alias BloodPressureRecord.Weights.Weight

  def list_daily_measurements(opts \\ []) do
    page =
      opts
      |> Keyword.get(:page, 1)
      |> normalize_positive_integer(1)

    per_page =
      opts
      |> Keyword.get(:per_page, 15)
      |> normalize_positive_integer(15)

    dates = list_measurement_dates()
    paged_dates = dates |> Enum.chunk_every(per_page) |> Enum.at(page - 1, [])

    build_daily_measurements(paged_dates)
  end

  def count_daily_measurements do
    list_measurement_dates()
    |> length()
  end

  def list_daily_measurements_for_graph do
    list_measurement_dates()
    |> build_daily_measurements()
  end

  defp list_measurement_dates do
    blood_pressure_dates =
      BloodPressure
      |> select([bp], fragment("date(?)", bp.measured_at))
      |> distinct(true)
      |> Repo.all()

    weight_dates =
      Weight
      |> select([w], fragment("date(?)", w.measured_at))
      |> distinct(true)
      |> Repo.all()

    (blood_pressure_dates ++ weight_dates)
    |> Enum.map(&normalize_date/1)
    |> Enum.uniq()
    |> Enum.sort({:desc, Date})
  end

  defp build_daily_measurements([]), do: []

  defp build_daily_measurements(dates) do
    blood_pressures_by_date =
      BloodPressure
      |> where([bp], fragment("date(?)", bp.measured_at) in ^dates)
      |> order_by([bp], desc: bp.measured_at, desc: bp.id)
      |> Repo.all()
      |> Enum.group_by(&NaiveDateTime.to_date(&1.measured_at))
      |> Map.new(fn {date, blood_pressures} -> {date, List.first(blood_pressures)} end)

    weights_by_date =
      Weight
      |> where([w], fragment("date(?)", w.measured_at) in ^dates)
      |> order_by([w], desc: w.measured_at, desc: w.id)
      |> Repo.all()
      |> Enum.group_by(&NaiveDateTime.to_date(&1.measured_at))
      |> Map.new(fn {date, weights} -> {date, List.first(weights)} end)

    Enum.map(dates, fn date ->
      %{
        date: date,
        blood_pressure: Map.get(blood_pressures_by_date, date),
        weight: Map.get(weights_by_date, date)
      }
    end)
  end

  defp normalize_positive_integer(nil, default), do: default
  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp normalize_date(%Date{} = date), do: date
  defp normalize_date(date) when is_binary(date), do: Date.from_iso8601!(date)
end
