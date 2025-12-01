defmodule BloodPressureRecord.BloodPressures.BloodPressure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blood_pressures" do
    field :systolic, :integer
    field :diastolic, :integer
    field :pulse, :integer
    field :measured_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blood_pressure, attrs) do
    blood_pressure
    |> cast(attrs, [:systolic, :diastolic, :pulse, :measured_at])
    |> validate_required([:systolic, :diastolic, :pulse, :measured_at])
  end
end
