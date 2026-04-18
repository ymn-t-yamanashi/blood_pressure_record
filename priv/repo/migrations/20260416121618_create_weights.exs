defmodule BloodPressureRecord.Repo.Migrations.CreateWeights do
  use Ecto.Migration

  def change do
    create table(:weights) do
      add :weight, :decimal, precision: 5, scale: 1
      add :measured_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
