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
    |> validate_number(:systolic,
      greater_than_or_equal_to: 60,
      less_than_or_equal_to: 250,
      message: "60〜250の範囲で入力してください"
    )
    |> validate_number(:diastolic,
      greater_than_or_equal_to: 30,
      less_than_or_equal_to: 150,
      message: "30〜150の範囲で入力してください"
    )
    |> validate_number(:pulse,
      greater_than_or_equal_to: 30,
      less_than_or_equal_to: 200,
      message: "30〜200の範囲で入力してください"
    )
  end
end
