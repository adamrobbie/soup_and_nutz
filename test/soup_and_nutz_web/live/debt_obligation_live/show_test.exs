defmodule SoupAndNutzWeb.DebtObligationLive.ShowTest do
  use SoupAndNutzWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoupAndNutz.FinancialInstrumentsFixtures

  @create_attrs %{
    debt_identifier: "DEBT001",
    debt_name: "Test Mortgage",
    debt_type: "MORTGAGE",
    outstanding_balance: "250000.00",
    interest_rate: "3.50",
    currency_code: "USD",
    reporting_entity: "Test Corp",
    reporting_period: "2024-Q1",
    is_active: true,
    maturity_date: ~D[2040-01-01],
    payment_frequency: "MONTHLY",
    collateral_type: "REAL_ESTATE"
  }

  defp create_debt_obligation(_) do
    debt_obligation = debt_obligation_fixture()
    %{debt_obligation: debt_obligation}
  end

  describe "Show" do
    test "displays debt obligation", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "Debt Obligation Details"
      assert html =~ debt_obligation.debt_name
      assert html =~ debt_obligation.debt_identifier
      assert html =~ debt_obligation.debt_type
      assert html =~ Decimal.to_string(debt_obligation.outstanding_balance)
      assert html =~ debt_obligation.currency_code
      assert html =~ debt_obligation.reporting_entity
      assert html =~ debt_obligation.reporting_period
    end

    test "displays debt obligation with all fields", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "Debt Obligation Details"
      assert html =~ "Test Mortgage"
      assert html =~ "DEBT001"
      assert html =~ "MORTGAGE"
      assert html =~ "250000.00"
      assert html =~ "3.50"
      assert html =~ "USD"
      assert html =~ "Test Corp"
      assert html =~ "2024-Q1"
      assert html =~ "Active"
      assert html =~ "MONTHLY"
      assert html =~ "REAL_ESTATE"
    end

    test "navigates to edit page", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, show_live, _html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Debt Obligation"

      assert_patch(show_live, ~p"/debt_obligations/#{debt_obligation}/edit")
    end

    test "navigates back to index", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, show_live, _html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert show_live |> element("a", "Back") |> render_click() =~
               "Debt Obligations"

      assert_patch(show_live, ~p"/debt_obligations")
    end

    test "displays XBRL compliance information", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      # Check for XBRL-related information
      assert html =~ "XBRL"
      assert html =~ "Compliance"
    end

    test "displays financial metrics", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      # Check for financial metrics display
      assert html =~ "Outstanding Balance"
      assert html =~ "Interest Rate"
      assert html =~ "Currency"
      assert html =~ "Payment Frequency"
    end

    test "handles debt obligation with inactive status", %{conn: conn} do
      inactive_debt = debt_obligation_fixture(%{@create_attrs | is_active: false})
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{inactive_debt}")

      assert html =~ "Inactive"
    end

    test "displays maturity date", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "2040-01-01"  # maturity_date
    end

    test "displays payment frequency information", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "MONTHLY"
      assert html =~ "Payment Frequency"
    end

    test "displays collateral information", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "REAL_ESTATE"
      assert html =~ "Collateral"
    end

    test "displays interest rate information", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "3.50"
      assert html =~ "Interest Rate"
    end

    test "displays reporting information", %{conn: conn} do
      debt_obligation = debt_obligation_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/debt_obligations/#{debt_obligation}")

      assert html =~ "Test Corp"
      assert html =~ "2024-Q1"
      assert html =~ "Reporting"
    end
  end
end
