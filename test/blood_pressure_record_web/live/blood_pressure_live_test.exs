defmodule BloodPressureRecordWeb.BloodPressureLiveTest do
  use BloodPressureRecordWeb.ConnCase

  import Phoenix.LiveViewTest
  import BloodPressureRecord.BloodPressuresFixtures

  @create_attrs %{systolic: 42, diastolic: 42, pulse: 42, measured_at: "2025-11-30T02:55:00"}
  @update_attrs %{systolic: 43, diastolic: 43, pulse: 43, measured_at: "2025-12-01T02:55:00"}
  @invalid_attrs %{systolic: nil, diastolic: nil, pulse: nil, measured_at: nil}
  defp create_blood_pressure(_) do
    blood_pressure = blood_pressure_fixture()

    %{blood_pressure: blood_pressure}
  end

  describe "Index" do
    setup [:create_blood_pressure]

    test "lists all blood_pressures", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/blood_pressures")

      assert html =~ "Listing Blood pressures"
    end

    test "saves new blood_pressure", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Blood pressure")
               |> render_click()
               |> follow_redirect(conn, ~p"/blood_pressures/new")

      assert render(form_live) =~ "New Blood pressure"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures")

      html = render(index_live)
      assert html =~ "Blood pressure created successfully"
    end

    test "updates blood_pressure in listing", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#blood_pressures-#{blood_pressure.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/blood_pressures/#{blood_pressure}/edit")

      assert render(form_live) =~ "Edit Blood pressure"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures")

      html = render(index_live)
      assert html =~ "Blood pressure updated successfully"
    end

    test "deletes blood_pressure in listing", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert index_live |> element("#blood_pressures-#{blood_pressure.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#blood_pressures-#{blood_pressure.id}")
    end
  end

  describe "Show" do
    setup [:create_blood_pressure]

    test "displays blood_pressure", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, _show_live, html} = live(conn, ~p"/blood_pressures/#{blood_pressure}")

      assert html =~ "Show Blood pressure"
    end

    test "updates blood_pressure and returns to show", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, show_live, _html} = live(conn, ~p"/blood_pressures/#{blood_pressure}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/blood_pressures/#{blood_pressure}/edit?return_to=show")

      assert render(form_live) =~ "Edit Blood pressure"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures/#{blood_pressure}")

      html = render(show_live)
      assert html =~ "Blood pressure updated successfully"
    end
  end
end
