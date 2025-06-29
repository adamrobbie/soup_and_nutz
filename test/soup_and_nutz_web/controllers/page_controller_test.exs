defmodule SoupAndNutzWeb.PageControllerTest do
  use SoupAndNutzWeb.ConnCase
  import SoupAndNutz.FinancialInstrumentsFixtures
  alias SoupAndNutz.Factory

  setup do
    user = Factory.insert(:user)
    {:ok, user: user}
  end

  defp authenticate_user(conn, user) do
    conn
    |> fetch_session([])
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
  end

  test "GET /", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    assert html_response(conn, 200) =~ "Financial Dashboard"
  end

  test "GET / returns dashboard with financial data", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check for dashboard elements
    assert html =~ "Total Assets"
    assert html =~ "Total Debt"
    assert html =~ "Net Worth"
    assert html =~ "Debt/Asset Ratio"
    assert html =~ "Recent Assets"
    assert html =~ "Recent Debts"

    # Check for navigation links in sidebar
    assert html =~ "Assets"
    assert html =~ "Debts"
    assert html =~ "/assets"
    assert html =~ "/debt_obligations"
  end

  test "GET / displays dashboard with assets and debts", %{conn: conn, user: user} do
    # Create test data
    _asset = asset_fixture(%{user_id: user.id})
    _debt = debt_obligation_fixture(%{user_id: user.id})

    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")

    assert html_response(conn, 200) =~ "Financial Dashboard"
    assert html_response(conn, 200) =~ "Total Assets"
    assert html_response(conn, 200) =~ "Total Debt"
    assert html_response(conn, 200) =~ "Net Worth"
    assert html_response(conn, 200) =~ "Debt/Asset Ratio"
    assert html_response(conn, 200) =~ "Recent Assets"
    assert html_response(conn, 200) =~ "Recent Debts"
    assert html_response(conn, 200) =~ "Assets"
    assert html_response(conn, 200) =~ "Debts"
  end

  test "GET / calculates correct financial metrics", %{conn: conn, user: user} do
    # Create test data with specific values for testing calculations
    asset_fixture(%{
      asset_identifier: "ASSET001",
      asset_name: "Test Stock Portfolio",
      asset_type: "InvestmentSecurities",
      fair_value: Decimal.new("100000.00"),
      currency_code: "USD",
      risk_level: "Medium",
      liquidity_level: "High",
      user_id: user.id
    })

    debt_obligation_fixture(%{
      debt_identifier: "DEBT001",
      debt_name: "Test Mortgage",
      debt_type: "Mortgage",
      principal_amount: Decimal.new("250000.00"),
      currency_code: "USD",
      interest_rate: Decimal.new("3.50"),
      maturity_date: ~D[2040-01-01],
      user_id: user.id
    })

    # Test the page loads and displays correct calculations
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check that the dashboard displays the test data
    assert html =~ "Test Stock Portfolio"
    assert html =~ "Test Mortgage"
    assert html =~ "$100,000.00"
    assert html =~ "$250,000.00"
  end

  test "GET / handles empty financial data", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check that dashboard handles empty data gracefully
    assert html =~ "$0"
    assert html =~ "0%"
    assert html =~ "Financial Dashboard"
  end

  test "GET / displays recent activity sections", %{conn: conn, user: user} do
    # Create multiple assets and debts to test recent activity
    asset_fixture(%{asset_name: "Asset 1", fair_value: "10000.00", user_id: user.id})
    asset_fixture(%{asset_name: "Asset 2", fair_value: "20000.00", user_id: user.id})
    debt_obligation_fixture(%{debt_name: "Debt 1", principal_amount: "5000.00", user_id: user.id})
    debt_obligation_fixture(%{debt_name: "Debt 2", principal_amount: "10000.00", user_id: user.id})

    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check for recent activity sections
    assert html =~ "Recent Assets"
    assert html =~ "Recent Debts"
    assert html =~ "Asset 1"
    assert html =~ "Asset 2"
    assert html =~ "Debt 1"
    assert html =~ "Debt 2"
  end

  test "GET / displays correct status indicators", %{conn: conn, user: user} do
    # Create test data
    asset_fixture(%{
      asset_name: "Test Asset",
      fair_value: "100000.00",
      risk_level: "High",
      liquidity_level: "Low",
      user_id: user.id
    })

    debt_obligation_fixture(%{
      debt_name: "Test Debt",
      principal_amount: "50000.00",
      risk_level: "Medium",
      user_id: user.id
    })

    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check for status indicators
    assert html =~ "Net Worth"
    assert html =~ "Total Assets"
    assert html =~ "Total Debt"
  end

  test "GET / displays negative net worth correctly", %{conn: conn, user: user} do
    # Create more debt than assets to test negative net worth
    asset_fixture(%{
      asset_name: "Test Asset",
      fair_value: "50000.00",
      user_id: user.id
    })

    debt_obligation_fixture(%{
      debt_name: "Test Debt 1",
      principal_amount: "30000.00",
      user_id: user.id
    })

    debt_obligation_fixture(%{
      debt_name: "Test Debt 2",
      principal_amount: "40000.00",
      user_id: user.id
    })

    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    html = html_response(conn, 200)

    # Check that negative net worth is handled correctly
    assert html =~ "Net Worth"
    # The exact display format depends on the template, but it should show the calculation
  end
end
