defmodule SoupAndNutzWeb.SoupAndNutzWeb.CashFlowLiveTest do
  use SoupAndNutzWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoupAndNutz.SoupAndNutzWebFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_cash_flow(_) do
    cash_flow = cash_flow_fixture()
    %{cash_flow: cash_flow}
  end

  describe "Index" do
    setup [:create_cash_flow]

    test "lists all cash_flows", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/soup_and_nutz_web/cash_flows")

      assert html =~ "Listing Cash flows"
    end

    test "saves new cash_flow", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/soup_and_nutz_web/cash_flows")

      assert index_live |> element("a", "New Cash flow") |> render_click() =~
               "New Cash flow"

      assert_patch(index_live, ~p"/soup_and_nutz_web/cash_flows/new")

      assert index_live
             |> form("#cash_flow-form", cash_flow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cash_flow-form", cash_flow: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/soup_and_nutz_web/cash_flows")

      html = render(index_live)
      assert html =~ "Cash flow created successfully"
    end

    test "updates cash_flow in listing", %{conn: conn, cash_flow: cash_flow} do
      {:ok, index_live, _html} = live(conn, ~p"/soup_and_nutz_web/cash_flows")

      assert index_live |> element("#cash_flows-#{cash_flow.id} a", "Edit") |> render_click() =~
               "Edit Cash flow"

      assert_patch(index_live, ~p"/soup_and_nutz_web/cash_flows/#{cash_flow}/edit")

      assert index_live
             |> form("#cash_flow-form", cash_flow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cash_flow-form", cash_flow: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/soup_and_nutz_web/cash_flows")

      html = render(index_live)
      assert html =~ "Cash flow updated successfully"
    end

    test "deletes cash_flow in listing", %{conn: conn, cash_flow: cash_flow} do
      {:ok, index_live, _html} = live(conn, ~p"/soup_and_nutz_web/cash_flows")

      assert index_live |> element("#cash_flows-#{cash_flow.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cash_flows-#{cash_flow.id}")
    end
  end

  describe "Show" do
    setup [:create_cash_flow]

    test "displays cash_flow", %{conn: conn, cash_flow: cash_flow} do
      {:ok, _show_live, html} = live(conn, ~p"/soup_and_nutz_web/cash_flows/#{cash_flow}")

      assert html =~ "Show Cash flow"
    end

    test "updates cash_flow within modal", %{conn: conn, cash_flow: cash_flow} do
      {:ok, show_live, _html} = live(conn, ~p"/soup_and_nutz_web/cash_flows/#{cash_flow}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Cash flow"

      assert_patch(show_live, ~p"/soup_and_nutz_web/cash_flows/#{cash_flow}/show/edit")

      assert show_live
             |> form("#cash_flow-form", cash_flow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#cash_flow-form", cash_flow: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/soup_and_nutz_web/cash_flows/#{cash_flow}")

      html = render(show_live)
      assert html =~ "Cash flow updated successfully"
    end
  end
end
