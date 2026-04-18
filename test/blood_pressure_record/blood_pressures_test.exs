defmodule BloodPressureRecord.BloodPressuresTest do
  use BloodPressureRecord.DataCase

  alias BloodPressureRecord.BloodPressures

  describe "blood_pressures" do
    alias BloodPressureRecord.BloodPressures.BloodPressure

    import BloodPressureRecord.BloodPressuresFixtures

    @invalid_attrs %{systolic: nil, diastolic: nil, pulse: nil, measured_at: nil}

    test "list_blood_pressures/0 returns all blood_pressures" do
      blood_pressure = blood_pressure_fixture()
      assert BloodPressures.list_blood_pressures() == [blood_pressure]
    end

    test "get_blood_pressure!/1 returns the blood_pressure with given id" do
      blood_pressure = blood_pressure_fixture()
      assert BloodPressures.get_blood_pressure!(blood_pressure.id) == blood_pressure
    end

    test "create_blood_pressure/1 with valid data creates a blood_pressure" do
      valid_attrs = %{
        systolic: 118,
        diastolic: 72,
        pulse: 62,
        measured_at: ~N[2025-11-30 02:55:00]
      }

      assert {:ok, %BloodPressure{} = blood_pressure} =
               BloodPressures.create_blood_pressure(valid_attrs)

      assert blood_pressure.systolic == 118
      assert blood_pressure.diastolic == 72
      assert blood_pressure.pulse == 62
      assert blood_pressure.measured_at == ~N[2025-11-30 02:55:00]
    end

    test "create_blood_pressure/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BloodPressures.create_blood_pressure(@invalid_attrs)
    end

    test "update_blood_pressure/2 with valid data updates the blood_pressure" do
      blood_pressure = blood_pressure_fixture()

      update_attrs = %{
        systolic: 121,
        diastolic: 76,
        pulse: 70,
        measured_at: ~N[2025-12-01 02:55:00]
      }

      assert {:ok, %BloodPressure{} = blood_pressure} =
               BloodPressures.update_blood_pressure(blood_pressure, update_attrs)

      assert blood_pressure.systolic == 121
      assert blood_pressure.diastolic == 76
      assert blood_pressure.pulse == 70
      assert blood_pressure.measured_at == ~N[2025-12-01 02:55:00]
    end

    test "update_blood_pressure/2 with invalid data returns error changeset" do
      blood_pressure = blood_pressure_fixture()

      assert {:error, %Ecto.Changeset{}} =
               BloodPressures.update_blood_pressure(blood_pressure, @invalid_attrs)

      assert blood_pressure == BloodPressures.get_blood_pressure!(blood_pressure.id)
    end

    test "delete_blood_pressure/1 deletes the blood_pressure" do
      blood_pressure = blood_pressure_fixture()
      assert {:ok, %BloodPressure{}} = BloodPressures.delete_blood_pressure(blood_pressure)

      assert_raise Ecto.NoResultsError, fn ->
        BloodPressures.get_blood_pressure!(blood_pressure.id)
      end
    end

    test "change_blood_pressure/1 returns a blood_pressure changeset" do
      blood_pressure = blood_pressure_fixture()
      assert %Ecto.Changeset{} = BloodPressures.change_blood_pressure(blood_pressure)
    end
  end
end
