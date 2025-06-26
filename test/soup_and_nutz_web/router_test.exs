defmodule SoupAndNutzWeb.RouterTest do
  use SoupAndNutzWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Financial Dashboard"
  end

  test "GET /assets", %{conn: conn} do
    conn = get(conn, ~p"/assets")
    assert html_response(conn, 200) =~ "Assets"
  end

  test "GET /assets/new", %{conn: conn} do
    conn = get(conn, ~p"/assets/new")
    assert html_response(conn, 200) =~ "New Asset"
  end

  test "GET /assets/:id", %{conn: conn} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture()
    conn = get(conn, ~p"/assets/#{asset}")
    assert html_response(conn, 200) =~ "Show Asset"
  end

  test "GET /assets/:id/edit", %{conn: conn} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture()
    conn = get(conn, ~p"/assets/#{asset}/edit")
    assert html_response(conn, 200) =~ "Edit Asset"
  end

  test "GET /debt_obligations", %{conn: conn} do
    conn = get(conn, ~p"/debt_obligations")
    assert html_response(conn, 200) =~ "Debt Obligations"
  end

  test "GET /debt_obligations/new", %{conn: conn} do
    conn = get(conn, ~p"/debt_obligations/new")
    assert html_response(conn, 200) =~ "New Debt Obligation"
  end

  test "GET /debt_obligations/:id", %{conn: conn} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture()
    conn = get(conn, ~p"/debt_obligations/#{debt}")
    assert html_response(conn, 200) =~ "Show Debt Obligation"
  end

  test "GET /debt_obligations/:id/edit", %{conn: conn} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture()
    conn = get(conn, ~p"/debt_obligations/#{debt}/edit")
    assert html_response(conn, 200) =~ "Edit Debt Obligation"
  end

  test "GET /health", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert json_response(conn, 200)["status"] == "ok"
  end

  test "GET /metrics", %{conn: conn} do
    conn = get(conn, ~p"/metrics")
    assert response(conn, 200) =~ "# HELP"
  end

  test "404 for unknown routes", %{conn: conn} do
    conn = get(conn, "/unknown-route")
    assert response(conn, 405) =~ "Method Not Allowed"
  end

  test "405 for unsupported methods", %{conn: conn} do
    conn = put(conn, ~p"/")
    assert response(conn, 405)
  end
end
