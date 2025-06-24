defmodule SoupAndNutzWeb.DebtObligationLive.IndexTest do
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
  @update_attrs %{
    debt_identifier: "DEBT002",
    debt_name: "Updated Mortgage",
    debt_type: "PERSONAL_LOAN",
    outstanding_balance: "50000.00",
    interest_rate: "5.25",
    currency_code: "EUR",
    reporting_entity: "Updated Corp",
    reporting_period: "2024-Q2",
    is_active: false,
    maturity_date: ~D[2030-01-01],
    payment_frequency: "WEEKLY",
    collateral_type: "VEHICLE"
  }
  @invalid_attrs %{
    debt_identifier: nil,
    debt_name: nil,
    debt_type: nil,
    outstanding_balance: nil,
    interest_rate: nil,
    currency_code: nil,
    reporting_entity: nil,
    reporting_period: nil,
    is_active: nil,
    maturity_date: nil,
    payment_frequency: nil,
    collateral_type: nil
  }

  defp create_debt_obligation(_) do
    debt_obligation = debt_obligation_fixture()
    %{debt_obligation: debt_obligation}
  end

  describe "Index" do
    test "lists all debt obligations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/debt_obligations")

      assert html =~ "Debt Obligations"
      assert html =~ "New Debt Obligation"
    end

    test "lists all debt obligations with data", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _index_live, html} = live(conn, ~p"/debt_obligations")

      assert html =~ debt_obligation.debt_name
      assert html =~ debt_obligation.debt_identifier
      assert html =~ debt_obligation.debt_type
      assert html =~ Decimal.to_string(debt_obligation.outstanding_balance)
    end

    test "saves new debt obligation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/debt_obligations")

      assert index_live |> element("a", "New Debt Obligation") |> render_click() =~
               "New Debt Obligation"

      assert_patch(index_live, ~p"/debt_obligations/new")

      assert index_live
             |> form("#debt_obligation-form", debt_obligation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#debt_obligation-form", debt_obligation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/debt_obligations")

      html = render(index_live)
      assert html =~ "Debt obligation created successfully"
      assert html =~ "Test Mortgage"
    end

    test "updates debt obligation in listing", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, index_live, _html} = live(conn, ~p"/debt_obligations")

      assert index_live |> element("#debt_obligations-#{debt_obligation.id} a", "Edit") |> render_click() =~
               "Edit Debt Obligation"

      assert_patch(index_live, ~p"/debt_obligations/#{debt_obligation}/edit")

      assert index_live
             |> form("#debt_obligation-form", debt_obligation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/debt_obligations")

      html = render(index_live)
      assert html =~ "Debt obligation updated successfully"
      assert html =~ "Updated Mortgage"
    end

    test "deletes debt obligation in listing", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, index_live, _html} = live(conn, ~p"/debt_obligations")

      assert index_live |> element("#debt_obligations-#{debt_obligation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#debt_obligations-#{debt_obligation.id}")
    end

    test "filters debt obligations by type", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, index_live, _html} = live(conn, ~p"/debt_obligations")

      # Test filtering by debt type
      assert index_live
             |> form("#filter-form", debt_type: debt_obligation.debt_type)
             |> render_submit()

      html = render(index_live)
      assert html =~ debt_obligation.debt_name
    end

    test "searches debt obligations by name", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, index_live, _html} = live(conn, ~p"/debt_obligations")

      # Test searching by debt name
      assert index_live
             |> form("#search-form", search: debt_obligation.debt_name)
             |> render_submit()

      html = render(index_live)
      assert html =~ debt_obligation.debt_name
    end

    test "displays debt summary statistics", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _index_live, html} = live(conn, ~p"/debt_obligations")

      # Check for summary statistics
      assert html =~ "Total Outstanding"
      assert html =~ "Average Interest Rate"
      assert html =~ "Monthly Payments"
    end

    test "displays XBRL compliance status", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, _index_live, html} = live(conn, ~p"/debt_obligations")

      # Check for XBRL compliance indicators
      assert html =~ "XBRL"
      assert html =~ "Compliance"
    end
  end
end
