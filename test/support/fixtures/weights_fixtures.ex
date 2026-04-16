defmodule BloodPressureRecord.WeightsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BloodPressureRecord.Weights` context.
  """

  @doc """
  Generate a weight.
  """
  def weight_fixture(attrs \\ %{}) do
    {:ok, weight} =
      attrs
      |> Enum.into(%{
        measured_at: ~N[2026-04-15 12:16:00],
        weight: "65.3"
      })
      |> BloodPressureRecord.Weights.create_weight()

    weight
  end
end
