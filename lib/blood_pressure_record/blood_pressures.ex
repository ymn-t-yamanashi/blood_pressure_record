defmodule BloodPressureRecord.BloodPressures do
  @moduledoc """
  The BloodPressures context.
  """

  import Ecto.Query, warn: false
  alias BloodPressureRecord.Repo

  alias BloodPressureRecord.BloodPressures.BloodPressure

  @doc """
  Returns the list of blood_pressures.

  ## Examples

      iex> list_blood_pressures()
      [%BloodPressure{}, ...]

  """
  def list_blood_pressures(opts \\ []) do
    page =
      opts
      |> Keyword.get(:page, 1)
      |> normalize_positive_integer(1)

    per_page =
      opts
      |> Keyword.get(:per_page)
      |> normalize_positive_integer(nil)

    BloodPressure
    |> order_by([bp], desc: bp.measured_at, desc: bp.id)
    |> maybe_paginate(page, per_page)
    |> Repo.all()
  end

  def count_blood_pressures do
    Repo.aggregate(BloodPressure, :count, :id)
  end

  @doc """
  Gets a single blood_pressure.

  Raises `Ecto.NoResultsError` if the Blood pressure does not exist.

  ## Examples

      iex> get_blood_pressure!(123)
      %BloodPressure{}

      iex> get_blood_pressure!(456)
      ** (Ecto.NoResultsError)

  """
  def get_blood_pressure!(id), do: Repo.get!(BloodPressure, id)

  @doc """
  Creates a blood_pressure.

  ## Examples

      iex> create_blood_pressure(%{field: value})
      {:ok, %BloodPressure{}}

      iex> create_blood_pressure(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_blood_pressure(attrs) do
    %BloodPressure{}
    |> BloodPressure.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a blood_pressure.

  ## Examples

      iex> update_blood_pressure(blood_pressure, %{field: new_value})
      {:ok, %BloodPressure{}}

      iex> update_blood_pressure(blood_pressure, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_blood_pressure(%BloodPressure{} = blood_pressure, attrs) do
    blood_pressure
    |> BloodPressure.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a blood_pressure.

  ## Examples

      iex> delete_blood_pressure(blood_pressure)
      {:ok, %BloodPressure{}}

      iex> delete_blood_pressure(blood_pressure)
      {:error, %Ecto.Changeset{}}

  """
  def delete_blood_pressure(%BloodPressure{} = blood_pressure) do
    Repo.delete(blood_pressure)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking blood_pressure changes.

  ## Examples

      iex> change_blood_pressure(blood_pressure)
      %Ecto.Changeset{data: %BloodPressure{}}

  """
  def change_blood_pressure(%BloodPressure{} = blood_pressure, attrs \\ %{}) do
    BloodPressure.changeset(blood_pressure, attrs)
  end

  defp maybe_paginate(query, _page, nil), do: query

  defp maybe_paginate(query, page, per_page) do
    offset = (page - 1) * per_page

    query
    |> limit(^per_page)
    |> offset(^offset)
  end

  defp normalize_positive_integer(nil, default), do: default
  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default
end
