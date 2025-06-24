defmodule SoupAndNutzWeb.AssetLive.FormComponentTest do
  use SoupAndNutzWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoupAndNutz.FinancialInstrumentsFixtures

  @create_attrs %{
    asset_identifier: "ASSET001",
    asset_name: "Test Stock Portfolio",
    asset_type: "EQUITY_SECURITIES",
    fair_value: "50000.00",
    currency_code: "USD",
    reporting_entity: "Test Corp",
    reporting_period: "2024-Q1",
    is_active: true,
    acquisition_date: ~D[2024-01-01],
    last_valuation_date: ~D[2024-01-15]
  }
  @update_attrs %{
    asset_identifier: "ASSET002",
    asset_name: "Updated Stock Portfolio",
    asset_type: "FIXED_INCOME_SECURITIES",
    fair_value: "75000.00",
    currency_code: "EUR",
    reporting_entity: "Updated Corp",
    reporting_period: "2024-Q2",
    is_active: false,
    acquisition_date: ~D[2024-02-01],
    last_valuation_date: ~D[2024-02-15]
  }
  @invalid_attrs %{
    asset_identifier: nil,
    asset_name: nil,
    asset_type: nil,
    fair_value: nil,
    currency_code: nil,
    reporting_entity: nil,
    reporting_period: nil,
    is_active: nil,
    acquisition_date: nil,
    last_valuation_date: nil
  }

  defp create_asset(_) do
    asset = asset_fixture()
    %{asset: asset}
  end

  describe "Form Component" do
    test "renders form for new asset", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      assert view |> element("h1") |> render() =~ "New Asset"
      assert view |> element("form") |> render() =~ "Save"
    end

    test "renders form for editing asset", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/assets/#{asset}/edit")

      assert view |> element("h1") |> render() =~ "Edit Asset"
      assert view |> element("form") |> render() =~ "Save"
      assert view |> element("input[name='asset[asset_name]']") |> render() =~ asset.asset_name
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      assert view
             |> form("#asset-form", asset: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"
    end

    test "validates asset identifier format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      invalid_attrs = %{@create_attrs | asset_identifier: "invalid-format"}

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "must be alphanumeric"
    end

    test "validates fair value is positive", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      invalid_attrs = %{@create_attrs | fair_value: "-1000.00"}

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "must be greater than 0"
    end

    test "validates currency code format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      invalid_attrs = %{@create_attrs | currency_code: "INVALID"}

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "must be a valid ISO 4217 currency code"
    end

    test "validates acquisition date is not in future", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      future_date = Date.add(Date.utc_today(), 1)
      invalid_attrs = %{@create_attrs | acquisition_date: future_date}

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "cannot be in the future"
    end

    test "validates last valuation date is not before acquisition date", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      invalid_attrs = %{@create_attrs |
        acquisition_date: ~D[2024-01-15],
        last_valuation_date: ~D[2024-01-01]
      }

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "cannot be before acquisition date"
    end

    test "creates asset with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      assert view
             |> form("#asset-form", asset: @create_attrs)
             |> render_submit()

      assert_patch(view, ~p"/assets")
      assert view |> element(".alert") |> render() =~ "Asset created successfully"
    end

    test "updates asset with valid data", %{conn: conn, asset: asset} do
      {:ok, view, _html} = live(conn, ~p"/assets/#{asset}/edit")

      assert view
             |> form("#asset-form", asset: @update_attrs)
             |> render_submit()

      assert_patch(view, ~p"/assets")
      assert view |> element(".alert") |> render() =~ "Asset updated successfully"
    end

    test "displays asset type options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      html = render(view)
      assert html =~ "EQUITY_SECURITIES"
      assert html =~ "FIXED_INCOME_SECURITIES"
      assert html =~ "REAL_ESTATE"
      assert html =~ "CASH_EQUIVALENTS"
      assert html =~ "ALTERNATIVE_INVESTMENTS"
    end

    test "displays currency code options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      html = render(view)
      assert html =~ "USD"
      assert html =~ "EUR"
      assert html =~ "GBP"
      assert html =~ "JPY"
    end

    test "handles form cancellation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      assert view |> element("a", "Cancel") |> render_click()
      assert_patch(view, ~p"/assets")
    end

    test "validates XBRL compliance rules", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/assets/new")

      # Test XBRL validation for asset type and currency mismatch
      invalid_attrs = %{@create_attrs |
        asset_type: "EQUITY_SECURITIES",
        currency_code: "JPY"  # JPY not typically used for equity securities
      }

      assert view
             |> form("#asset-form", asset: invalid_attrs)
             |> render_change() =~ "XBRL compliance"
    end
  end
end
