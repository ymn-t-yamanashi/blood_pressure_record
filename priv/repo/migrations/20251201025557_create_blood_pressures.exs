defmodule BloodPressureRecord.Repo.Migrations.CreateBloodPressures do
  use Ecto.Migration

  def change do
    create table(:blood_pressures) do
      add :systolic, :integer
      add :diastolic, :integer
      add :pulse, :integer
      add :measured_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
