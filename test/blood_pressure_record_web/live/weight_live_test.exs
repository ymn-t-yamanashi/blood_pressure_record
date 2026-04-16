defmodule BloodPressureRecordWeb.WeightLiveTest do
  use BloodPressureRecordWeb.ConnCase

  import Phoenix.LiveViewTest
  import BloodPressureRecord.WeightsFixtures

  @create_attrs %{weight: "65.3", measured_at: "2026-04-15T12:16:00"}
  @update_attrs %{weight: "66.4", measured_at: "2026-04-16T12:16:00"}
  @invalid_attrs %{weight: nil, measured_at: nil}
  defp create_weight(_) do
    weight = weight_fixture()

    %{weight: weight}
  end

  describe "Index" do
    setup [:create_weight]

    test "lists all weights", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/weights")

      assert html =~ "体重一覧"
    end

    test "saves new weight", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/weights")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "体重を追加")
               |> render_click()
               |> follow_redirect(conn, ~p"/weights/new")

      assert render(form_live) =~ "体重を追加"

      assert form_live
             |> form("#weight-form", weight: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#weight-form", weight: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/weights")

      html = render(index_live)
      assert html =~ "作成しました"
    end

    test "updates weight in listing", %{conn: conn, weight: weight} do
      {:ok, index_live, _html} = live(conn, ~p"/weights")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#weights-#{weight.id} a", "編集")
               |> render_click()
               |> follow_redirect(conn, ~p"/weights/#{weight}/edit")

      assert render(form_live) =~ "体重を編集"

      assert form_live
             |> form("#weight-form", weight: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#weight-form", weight: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/weights")

      html = render(index_live)
      assert html =~ "更新しました"
    end

    test "deletes weight in listing", %{conn: conn, weight: weight} do
      {:ok, index_live, _html} = live(conn, ~p"/weights")

      assert index_live |> element("#weights-#{weight.id} a", "削除") |> render_click()
      refute has_element?(index_live, "#weights-#{weight.id}")
    end
  end

  describe "Show" do
    setup [:create_weight]

    test "displays weight", %{conn: conn, weight: weight} do
      {:ok, _show_live, html} = live(conn, ~p"/weights/#{weight}")

      assert html =~ "体重詳細"
    end

    test "updates weight and returns to show", %{conn: conn, weight: weight} do
      {:ok, show_live, _html} = live(conn, ~p"/weights/#{weight}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "編集")
               |> render_click()
               |> follow_redirect(conn, ~p"/weights/#{weight}/edit?return_to=show")

      assert render(form_live) =~ "体重を編集"

      assert form_live
             |> form("#weight-form", weight: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#weight-form", weight: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/weights/#{weight}")

      html = render(show_live)
      assert html =~ "更新しました"
    end
  end
end
