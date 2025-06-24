defmodule SoupAndNutzWeb.PageControllerTest do
  use SoupAndNutzWeb.ConnCase

  import SoupAndNutz.FinancialInstrumentsFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Financial Dashboard"
  end

  test "GET / returns dashboard with financial data", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check for dashboard elements
    assert html =~ "Total Assets"
    assert html =~ "Total Debt"
    assert html =~ "Net Worth"
    assert html =~ "Debt/Asset Ratio"
    assert html =~ "Assets by Type"
    assert html =~ "Debts by Type"
    assert html =~ "Assets by Currency"
    assert html =~ "Debts by Currency"
    assert html =~ "Recent Assets"
    assert html =~ "Recent Debts"

    # Check for navigation links
    assert html =~ "Manage Assets"
    assert html =~ "Manage Debts"
    assert html =~ "/assets"
    assert html =~ "/debt_obligations"
  end

  test "GET / displays dashboard with assets and debts", %{conn: conn} do
    # Create test data
    asset = asset_fixture(%{
      asset_identifier: "ASSET001",
      asset_name: "Test Stock Portfolio",
      asset_type: "EQUITY_SECURITIES",
      fair_value: "50000.00",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1"
    })

    debt = debt_obligation_fixture(%{
      debt_identifier: "DEBT001",
      debt_name: "Test Mortgage",
      debt_type: "MORTGAGE",
      outstanding_balance: "250000.00",
      interest_rate: "3.50",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1"
    })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that the dashboard displays the test data
    assert html =~ "Test Stock Portfolio"
    assert html =~ "Test Mortgage"
    assert html =~ "50000.00"
    assert html =~ "250000.00"
  end

  test "GET / calculates correct financial metrics", %{conn: conn} do
    # Create test data with known values
    asset_fixture(%{
      asset_identifier: "ASSET001",
      asset_name: "Test Asset",
      asset_type: "EQUITY_SECURITIES",
      fair_value: "100000.00",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1"
    })

    debt_obligation_fixture(%{
      debt_identifier: "DEBT001",
      debt_name: "Test Debt",
      debt_type: "MORTGAGE",
      outstanding_balance: "60000.00",
      interest_rate: "3.50",
      currency_code: "USD",
      reporting_entity: "Test Corp",
      reporting_period: "2024-Q1"
    })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that calculations are correct
    # Total Assets: 100000.00
    # Total Debt: 60000.00
    # Net Worth: 40000.00
    # Debt/Asset Ratio: 60%
    assert html =~ "100000.00"
    assert html =~ "60000.00"
    assert html =~ "40000.00"
    assert html =~ "60.0%"
  end

  test "GET / handles empty financial data", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that dashboard handles empty data gracefully
    assert html =~ "$0"
    assert html =~ "0%"
    assert html =~ "Financial Dashboard"
  end

  test "GET / displays chart containers", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check for chart containers
    assert html =~ "assetsByTypeChart"
    assert html =~ "debtsByTypeChart"
    assert html =~ "assetsByCurrencyChart"
    assert html =~ "debtsByCurrencyChart"
  end

  test "GET / includes Chart.js script", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check for Chart.js integration
    assert html =~ "Chart.js"
    assert html =~ "new Chart"
  end

  test "GET / displays recent activity sections", %{conn: conn} do
    # Create multiple assets and debts to test recent activity
    asset_fixture(%{asset_name: "Asset 1", fair_value: "10000.00"})
    asset_fixture(%{asset_name: "Asset 2", fair_value: "20000.00"})
    asset_fixture(%{asset_name: "Asset 3", fair_value: "30000.00"})
    asset_fixture(%{asset_name: "Asset 4", fair_value: "40000.00"})
    asset_fixture(%{asset_name: "Asset 5", fair_value: "50000.00"})
    asset_fixture(%{asset_name: "Asset 6", fair_value: "60000.00"})

    debt_obligation_fixture(%{debt_name: "Debt 1", outstanding_balance: "10000.00"})
    debt_obligation_fixture(%{debt_name: "Debt 2", outstanding_balance: "20000.00"})
    debt_obligation_fixture(%{debt_name: "Debt 3", outstanding_balance: "30000.00"})
    debt_obligation_fixture(%{debt_name: "Debt 4", outstanding_balance: "40000.00"})
    debt_obligation_fixture(%{debt_name: "Debt 5", outstanding_balance: "50000.00"})
    debt_obligation_fixture(%{debt_name: "Debt 6", outstanding_balance: "60000.00"})

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that recent activity shows the most recent 5 items
    assert html =~ "Recent Assets"
    assert html =~ "Recent Debts"
    assert html =~ "View all assets"
    assert html =~ "View all debts"
  end

  test "GET / displays correct status indicators", %{conn: conn} do
    # Create asset with positive net worth
    asset_fixture(%{
      asset_name: "Test Asset",
      fair_value: "100000.00",
      currency_code: "USD"
    })

    debt_obligation_fixture(%{
      debt_name: "Test Debt",
      outstanding_balance: "50000.00",
      currency_code: "USD"
    })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that net worth is displayed in green (positive)
    assert html =~ "text-green-600"
  end

  test "GET / displays negative net worth correctly", %{conn: conn} do
    # Create debt larger than assets
    asset_fixture(%{
      asset_name: "Test Asset",
      fair_value: "50000.00",
      currency_code: "USD"
    })

    debt_obligation_fixture(%{
      debt_name: "Test Debt",
      outstanding_balance: "100000.00",
      currency_code: "USD"
    })

    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    # Check that net worth is displayed in red (negative)
    assert html =~ "text-red-600"
  end
end
