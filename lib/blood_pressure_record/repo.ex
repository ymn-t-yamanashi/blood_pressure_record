defmodule BloodPressureRecord.Repo do
  use Ecto.Repo,
    otp_app: :blood_pressure_record,
    adapter: Ecto.Adapters.SQLite3
end
