defmodule SoupAndNutzWeb.AssetLive.ShowTest do
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

  defp create_asset(_) do
    asset = asset_fixture()
    %{asset: asset}
  end

  describe "Show" do
    test "displays asset", %{conn: conn, asset: asset} do
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      assert html =~ "Asset Details"
      assert html =~ asset.asset_name
      assert html =~ asset.asset_identifier
      assert html =~ asset.asset_type
      assert html =~ Decimal.to_string(asset.fair_value)
      assert html =~ asset.currency_code
      assert html =~ asset.reporting_entity
      assert html =~ asset.reporting_period
    end

    test "displays asset with all fields", %{conn: conn} do
      asset = asset_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      assert html =~ "Asset Details"
      assert html =~ "Test Stock Portfolio"
      assert html =~ "ASSET001"
      assert html =~ "EQUITY_SECURITIES"
      assert html =~ "50000.00"
      assert html =~ "USD"
      assert html =~ "Test Corp"
      assert html =~ "2024-Q1"
      assert html =~ "Active"
    end

    test "navigates to edit page", %{conn: conn, asset: asset} do
      {:ok, show_live, _html} = live(conn, ~p"/assets/#{asset}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Asset"

      assert_patch(show_live, ~p"/assets/#{asset}/edit")
    end

    test "navigates back to index", %{conn: conn, asset: asset} do
      {:ok, show_live, _html} = live(conn, ~p"/assets/#{asset}")

      assert show_live |> element("a", "Back") |> render_click() =~
               "Assets"

      assert_patch(show_live, ~p"/assets")
    end

    test "displays XBRL compliance information", %{conn: conn, asset: asset} do
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      # Check for XBRL-related information
      assert html =~ "XBRL"
      assert html =~ "Compliance"
    end

    test "displays financial metrics", %{conn: conn, asset: asset} do
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      # Check for financial metrics display
      assert html =~ "Fair Value"
      assert html =~ "Currency"
      assert html =~ "Reporting"
    end

    test "handles asset with inactive status", %{conn: conn} do
      inactive_asset = asset_fixture(%{@create_attrs | is_active: false})
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{inactive_asset}")

      assert html =~ "Inactive"
    end

    test "displays acquisition and valuation dates", %{conn: conn} do
      asset = asset_fixture(@create_attrs)
      {:ok, _show_live, html} = live(conn, ~p"/assets/#{asset}")

      assert html =~ "2024-01-01"  # acquisition_date
      assert html =~ "2024-01-15"  # last_valuation_date
    end
  end
end
