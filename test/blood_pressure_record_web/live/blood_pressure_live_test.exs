defmodule BloodPressureRecordWeb.BloodPressureLiveTest do
  use BloodPressureRecordWeb.ConnCase

  import Phoenix.LiveViewTest
  import BloodPressureRecord.BloodPressuresFixtures
  import BloodPressureRecord.WeightsFixtures

  @create_attrs %{systolic: 118, diastolic: 72, pulse: 62, measured_at: "2025-11-30T02:55:00"}
  @update_attrs %{systolic: 121, diastolic: 76, pulse: 70, measured_at: "2025-12-01T02:55:00"}
  @invalid_attrs %{systolic: nil, diastolic: nil, pulse: nil, measured_at: nil}
  defp create_blood_pressure(_) do
    blood_pressure = blood_pressure_fixture()

    %{blood_pressure: blood_pressure}
  end

  describe "Index" do
    setup [:create_blood_pressure]

    test "lists all blood_pressures", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/blood_pressures")

      assert html =~ "血圧一覧"
    end

    test "saves new blood_pressure", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "血圧を追加")
               |> render_click()
               |> follow_redirect(conn, ~p"/blood_pressures/new")

      assert render(form_live) =~ "血圧を追加"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures")

      html = render(index_live)
      assert html =~ "作成しました"
    end

    test "updates blood_pressure in listing", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#blood_pressures-#{blood_pressure.id} a", "編集")
               |> render_click()
               |> follow_redirect(conn, ~p"/blood_pressures/#{blood_pressure}/edit")

      assert render(form_live) =~ "血圧を編集"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures")

      html = render(index_live)
      assert html =~ "更新しました"
    end

    test "deletes blood_pressure in listing", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, index_live, _html} = live(conn, ~p"/blood_pressures")

      assert index_live
             |> element("#blood_pressures-#{blood_pressure.id} a", "削除")
             |> render_click()

      refute has_element?(index_live, "#blood_pressures-#{blood_pressure.id}")
    end
  end

  describe "Show" do
    setup [:create_blood_pressure]

    test "displays blood_pressure", %{conn: conn, blood_pressure: blood_pressure} do
      {:ok, _show_live, html} = live(conn, ~p"/blood_pressures/#{blood_pressure}")

      assert html =~ "血圧詳細"
    end

    test "updates blood_pressure and returns to show", %{
      conn: conn,
      blood_pressure: blood_pressure
    } do
      {:ok, show_live, _html} = live(conn, ~p"/blood_pressures/#{blood_pressure}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "編集")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/blood_pressures/#{blood_pressure}/edit?return_to=show"
               )

      assert render(form_live) =~ "血圧を編集"

      assert form_live
             |> form("#blood_pressure-form", blood_pressure: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#blood_pressure-form", blood_pressure: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/blood_pressures/#{blood_pressure}")

      html = render(show_live)
      assert html =~ "更新しました"
    end
  end

  describe "Upload graph" do
    setup [:create_blood_pressure]

    test "shows systolic and diastolic by default", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#upload-graph-visibility-form")
      assert has_element?(view, "#upload-graph-series-form")
      assert has_element?(view, "#upload-visibility-systolic[checked]")
      assert has_element?(view, "#upload-visibility-diastolic[checked]")
      assert has_element?(view, "#upload-visibility-weight[checked]")
      refute has_element?(view, "#upload-visibility-pulse[checked]")
      assert has_element?(view, "#graph-series-both[checked]")
      refute has_element?(view, "#graph-series-actual[checked]")
      refute has_element?(view, "#graph-series-average[checked]")
      assert has_element?(view, "img")
    end

    test "updates visible metrics from the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#upload-graph-visibility-form", %{"visibility" => ["pulse"]})
      |> render_change()

      refute has_element?(view, "#upload-visibility-systolic[checked]")
      refute has_element?(view, "#upload-visibility-diastolic[checked]")
      refute has_element?(view, "#upload-visibility-weight[checked]")
      assert has_element?(view, "#upload-visibility-pulse[checked]")
      assert has_element?(view, "img")
    end

    test "updates graph series mode from the form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> form("#upload-graph-series-form", %{"graph_series" => %{"series_mode" => "average"}})
      |> render_change()

      refute has_element?(view, "#graph-series-both[checked]")
      refute has_element?(view, "#graph-series-actual[checked]")
      assert has_element?(view, "#graph-series-average[checked]")
      assert has_element?(view, "img")
    end

    test "high risk cells are highlighted in the latest table", %{conn: conn} do
      blood_pressure =
        blood_pressure_fixture(%{
          systolic: 168,
          diastolic: 104,
          pulse: 124,
          measured_at: ~N[2025-12-02 02:55:00]
        })

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "td.bg-rose-300", Integer.to_string(blood_pressure.systolic))
      assert has_element?(view, "td.bg-rose-300", Integer.to_string(blood_pressure.diastolic))
      assert has_element?(view, "td.bg-rose-300", Integer.to_string(blood_pressure.pulse))
    end

    test "weekend dates are highlighted in the latest table", %{conn: conn} do
      blood_pressure_fixture(%{
        systolic: 120,
        diastolic: 74,
        pulse: 64,
        measured_at: ~N[2025-12-06 09:00:00]
      })

      blood_pressure_fixture(%{
        systolic: 122,
        diastolic: 76,
        pulse: 66,
        measured_at: ~N[2025-12-07 09:00:00]
      })

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "td.bg-sky-100", "2025/12/06")
      assert has_element?(view, "td.bg-pink-100", "2025/12/07")
    end

    test "weight status is judged by BMI from height", %{conn: conn} do
      weight_fixture(%{weight: "80.0", measured_at: ~N[2025-12-08 09:00:00]})

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "#latest-averages", "太りすぎ")

      view
      |> form("#weight-profile-form", %{"weight_profile" => %{"height_cm" => "180"}})
      |> render_change()

      assert has_element?(view, "#latest-averages", "標準より高め")

      view
      |> form("#weight-profile-form", %{"weight_profile" => %{"height_cm" => "191"}})
      |> render_change()

      assert has_element?(view, "#latest-averages", "標準")
    end

    test "weight cells are highlighted by BMI status", %{conn: conn} do
      weight_fixture(%{weight: "60.0", measured_at: ~N[2025-12-09 09:00:00]})
      weight_fixture(%{weight: "65.0", measured_at: ~N[2025-12-08 09:00:00]})
      weight_fixture(%{weight: "80.0", measured_at: ~N[2025-12-07 09:00:00]})

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "td.bg-emerald-50", "60.0")
      assert has_element?(view, "td.bg-amber-50", "65.0")
      assert has_element?(view, "td.bg-rose-50", "80.0")
    end
  end
end
