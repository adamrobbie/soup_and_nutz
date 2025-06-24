defmodule SoupAndNutzWeb.DebtObligationLive.FormComponentTest do
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

  describe "Form Component" do
    test "renders form for new debt obligation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      assert view |> element("h1") |> render() =~ "New Debt Obligation"
      assert view |> element("form") |> render() =~ "Save"
    end

    test "renders form for editing debt obligation", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/#{debt_obligation}/edit")

      assert view |> element("h1") |> render() =~ "Edit Debt Obligation"
      assert view |> element("form") |> render() =~ "Save"
      assert view |> element("input[name='debt_obligation[debt_name]']") |> render() =~ debt_obligation.debt_name
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      assert view
             |> form("#debt_obligation-form", debt_obligation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"
    end

    test "validates debt identifier format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      invalid_attrs = %{@create_attrs | debt_identifier: "invalid-format"}

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "must be alphanumeric"
    end

    test "validates outstanding balance is positive", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      invalid_attrs = %{@create_attrs | outstanding_balance: "-1000.00"}

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "must be greater than 0"
    end

    test "validates interest rate is within valid range", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      invalid_attrs = %{@create_attrs | interest_rate: "25.00"}

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "must be between 0 and 20"
    end

    test "validates currency code format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      invalid_attrs = %{@create_attrs | currency_code: "INVALID"}

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "must be a valid ISO 4217 currency code"
    end

    test "validates maturity date is in future", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      past_date = Date.add(Date.utc_today(), -1)
      invalid_attrs = %{@create_attrs | maturity_date: past_date}

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "must be in the future"
    end

    test "creates debt obligation with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      assert view
             |> form("#debt_obligation-form", debt_obligation: @create_attrs)
             |> render_submit()

      assert_patch(view, ~p"/debt_obligations")
      assert view |> element(".alert") |> render() =~ "Debt obligation created successfully"
    end

    test "updates debt obligation with valid data", %{conn: conn, debt_obligation: debt_obligation} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/#{debt_obligation}/edit")

      assert view
             |> form("#debt_obligation-form", debt_obligation: @update_attrs)
             |> render_submit()

      assert_patch(view, ~p"/debt_obligations")
      assert view |> element(".alert") |> render() =~ "Debt obligation updated successfully"
    end

    test "displays debt type options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      html = render(view)
      assert html =~ "MORTGAGE"
      assert html =~ "PERSONAL_LOAN"
      assert html =~ "CREDIT_CARD"
      assert html =~ "BUSINESS_LOAN"
      assert html =~ "STUDENT_LOAN"
    end

    test "displays payment frequency options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      html = render(view)
      assert html =~ "MONTHLY"
      assert html =~ "WEEKLY"
      assert html =~ "QUARTERLY"
      assert html =~ "ANNUALLY"
    end

    test "displays collateral type options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      html = render(view)
      assert html =~ "REAL_ESTATE"
      assert html =~ "VEHICLE"
      assert html =~ "EQUIPMENT"
      assert html =~ "INVENTORY"
      assert html =~ "NONE"
    end

    test "displays currency code options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      html = render(view)
      assert html =~ "USD"
      assert html =~ "EUR"
      assert html =~ "GBP"
      assert html =~ "JPY"
    end

    test "handles form cancellation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      assert view |> element("a", "Cancel") |> render_click()
      assert_patch(view, ~p"/debt_obligations")
    end

    test "validates XBRL compliance rules", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      # Test XBRL validation for debt type and currency mismatch
      invalid_attrs = %{@create_attrs |
        debt_type: "MORTGAGE",
        currency_code: "JPY"  # JPY not typically used for mortgages
      }

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "XBRL compliance"
    end

    test "validates payment frequency for debt type", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/debt_obligations/new")

      # Test validation for inappropriate payment frequency
      invalid_attrs = %{@create_attrs |
        debt_type: "MORTGAGE",
        payment_frequency: "WEEKLY"  # Mortgages typically monthly
      }

      assert view
             |> form("#debt_obligation-form", debt_obligation: invalid_attrs)
             |> render_change() =~ "payment frequency"
    end
  end
end
