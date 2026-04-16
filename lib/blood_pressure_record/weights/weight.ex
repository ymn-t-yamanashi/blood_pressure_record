defmodule BloodPressureRecord.Weights.Weight do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weights" do
    field :weight, :decimal
    field :measured_at, :naive_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(weight, attrs) do
    weight
    |> cast(attrs, [:weight, :measured_at])
    |> validate_required([:weight, :measured_at])
    |> validate_number(:weight,
      greater_than_or_equal_to: Decimal.new("30.0"),
      less_than_or_equal_to: Decimal.new("250.0"),
      message: "30.0〜250.0kgの範囲で入力してください"
    )
  end
end
