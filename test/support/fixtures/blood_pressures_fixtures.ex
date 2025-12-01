defmodule BloodPressureRecord.BloodPressuresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BloodPressureRecord.BloodPressures` context.
  """

  @doc """
  Generate a blood_pressure.
  """
  def blood_pressure_fixture(attrs \\ %{}) do
    {:ok, blood_pressure} =
      attrs
      |> Enum.into(%{
        diastolic: 42,
        measured_at: ~N[2025-11-30 02:55:00],
        pulse: 42,
        systolic: 42
      })
      |> BloodPressureRecord.BloodPressures.create_blood_pressure()

    blood_pressure
  end
end
