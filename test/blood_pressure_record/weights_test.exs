defmodule BloodPressureRecord.WeightsTest do
  use BloodPressureRecord.DataCase

  alias BloodPressureRecord.Weights

  describe "weights" do
    alias BloodPressureRecord.Weights.Weight

    import BloodPressureRecord.WeightsFixtures

    @invalid_attrs %{weight: nil, measured_at: nil}

    test "list_weights/0 returns all weights" do
      weight = weight_fixture()
      assert Weights.list_weights() == [weight]
    end

    test "get_weight!/1 returns the weight with given id" do
      weight = weight_fixture()
      assert Weights.get_weight!(weight.id) == weight
    end

    test "create_weight/1 with valid data creates a weight" do
      valid_attrs = %{weight: "65.3", measured_at: ~N[2026-04-15 12:16:00]}

      assert {:ok, %Weight{} = weight} = Weights.create_weight(valid_attrs)
      assert weight.weight == Decimal.new("65.3")
      assert weight.measured_at == ~N[2026-04-15 12:16:00]
    end

    test "create_weight/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Weights.create_weight(@invalid_attrs)
    end

    test "update_weight/2 with valid data updates the weight" do
      weight = weight_fixture()
      update_attrs = %{weight: "66.4", measured_at: ~N[2026-04-16 12:16:00]}

      assert {:ok, %Weight{} = weight} = Weights.update_weight(weight, update_attrs)
      assert weight.weight == Decimal.new("66.4")
      assert weight.measured_at == ~N[2026-04-16 12:16:00]
    end

    test "create_weight/1 rejects values outside the allowed range" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Weights.create_weight(%{weight: "25.0", measured_at: ~N[2026-04-15 12:16:00]})

      assert "30.0〜250.0kgの範囲で入力してください" in errors_on(changeset).weight
    end

    test "update_weight/2 with invalid data returns error changeset" do
      weight = weight_fixture()
      assert {:error, %Ecto.Changeset{}} = Weights.update_weight(weight, @invalid_attrs)
      assert weight == Weights.get_weight!(weight.id)
    end

    test "delete_weight/1 deletes the weight" do
      weight = weight_fixture()
      assert {:ok, %Weight{}} = Weights.delete_weight(weight)
      assert_raise Ecto.NoResultsError, fn -> Weights.get_weight!(weight.id) end
    end

    test "change_weight/1 returns a weight changeset" do
      weight = weight_fixture()
      assert %Ecto.Changeset{} = Weights.change_weight(weight)
    end
  end
end
