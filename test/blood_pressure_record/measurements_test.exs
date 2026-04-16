defmodule BloodPressureRecord.MeasurementsTest do
  use BloodPressureRecord.DataCase

  alias BloodPressureRecord.Measurements

  import BloodPressureRecord.BloodPressuresFixtures
  import BloodPressureRecord.WeightsFixtures

  test "list_daily_measurements/1 merges dates from blood pressures and weights" do
    blood_pressure_fixture(%{measured_at: ~N[2025-12-03 08:00:00]})
    weight_fixture(%{measured_at: ~N[2025-12-02 09:00:00]})

    measurements = Measurements.list_daily_measurements(page: 1, per_page: 15)

    assert Enum.map(measurements, & &1.date) == [~D[2025-12-03], ~D[2025-12-02]]
    assert Enum.at(measurements, 0).blood_pressure
    assert is_nil(Enum.at(measurements, 0).weight)
    assert Enum.at(measurements, 1).weight
  end

  test "list_daily_measurements/1 picks the latest measured_at per day and type" do
    blood_pressure_fixture(%{systolic: 118, measured_at: ~N[2025-12-03 08:00:00]})
    latest_bp = blood_pressure_fixture(%{systolic: 130, measured_at: ~N[2025-12-03 10:00:00]})
    weight_fixture(%{weight: "64.0", measured_at: ~N[2025-12-03 07:00:00]})
    latest_weight = weight_fixture(%{weight: "66.0", measured_at: ~N[2025-12-03 11:00:00]})

    [measurement] = Measurements.list_daily_measurements(page: 1, per_page: 15)

    assert measurement.blood_pressure.id == latest_bp.id
    assert measurement.weight.id == latest_weight.id
  end
end
