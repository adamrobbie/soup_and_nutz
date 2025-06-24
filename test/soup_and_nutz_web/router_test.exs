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
    assert html_response(conn, 200) =~ "Asset Details"
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
    assert html_response(conn, 200) =~ "Debt Obligation Details"
  end

  test "GET /debt_obligations/:id/edit", %{conn: conn} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture()
    conn = get(conn, ~p"/debt_obligations/#{debt}/edit")
    assert html_response(conn, 200) =~ "Edit Debt Obligation"
  end

  test "POST /assets", %{conn: conn} do
    asset_attrs = %{
      asset_identifier: "TEST001",
      asset_name: "Test Asset",
      asset_type: "EQUITY_SECURITIES",
      fair_value: "10000.00",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1",
      is_active: true,
      acquisition_date: ~D[2024-01-01],
      last_valuation_date: ~D[2024-01-15]
    }

    conn = post(conn, ~p"/assets", asset: asset_attrs)
    assert redirected_to(conn) == ~p"/assets"
  end

  test "PATCH /assets/:id", %{conn: conn} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture()
    update_attrs = %{asset_name: "Updated Asset Name"}

    conn = patch(conn, ~p"/assets/#{asset}", asset: update_attrs)
    assert redirected_to(conn) == ~p"/assets"
  end

  test "DELETE /assets/:id", %{conn: conn} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture()

    conn = delete(conn, ~p"/assets/#{asset}")
    assert redirected_to(conn) == ~p"/assets"
  end

  test "POST /debt_obligations", %{conn: conn} do
    debt_attrs = %{
      debt_identifier: "DEBT001",
      debt_name: "Test Debt",
      debt_type: "MORTGAGE",
      outstanding_balance: "100000.00",
      interest_rate: "3.50",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1",
      is_active: true,
      maturity_date: ~D[2040-01-01],
      payment_frequency: "MONTHLY",
      collateral_type: "REAL_ESTATE"
    }

    conn = post(conn, ~p"/debt_obligations", debt_obligation: debt_attrs)
    assert redirected_to(conn) == ~p"/debt_obligations"
  end

  test "PATCH /debt_obligations/:id", %{conn: conn} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture()
    update_attrs = %{debt_name: "Updated Debt Name"}

    conn = patch(conn, ~p"/debt_obligations/#{debt}", debt_obligation: update_attrs)
    assert redirected_to(conn) == ~p"/debt_obligations"
  end

  test "DELETE /debt_obligations/:id", %{conn: conn} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture()

    conn = delete(conn, ~p"/debt_obligations/#{debt}")
    assert redirected_to(conn) == ~p"/debt_obligations"
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
    assert html_response(conn, 404) =~ "Not Found"
  end

  test "405 for unsupported methods", %{conn: conn} do
    conn = put(conn, ~p"/")
    assert response(conn, 405)
  end
end
