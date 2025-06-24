defmodule SoupAndNutzWeb.AssetLive.IndexTest do
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

  describe "Index" do
    test "lists all assets", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/assets")

      assert html =~ "Assets"
      assert html =~ "New Asset"
    end

    test "lists all assets with data", %{conn: conn, asset: asset} do
      {:ok, _index_live, html} = live(conn, ~p"/assets")

      assert html =~ asset.asset_name
      assert html =~ asset.asset_identifier
      assert html =~ asset.asset_type
      assert html =~ Decimal.to_string(asset.fair_value)
    end

    test "saves new asset", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("a", "New Asset") |> render_click() =~
               "New Asset"

      assert_patch(index_live, ~p"/assets/new")

      assert index_live
             |> form("#asset-form", asset: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#asset-form", asset: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assets")

      html = render(index_live)
      assert html =~ "Asset created successfully"
      assert html =~ "Test Stock Portfolio"
    end

    test "updates asset in listing", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("#assets-#{asset.id} a", "Edit") |> render_click() =~
               "Edit Asset"

      assert_patch(index_live, ~p"/assets/#{asset}/edit")

      assert index_live
             |> form("#asset-form", asset: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/assets")

      html = render(index_live)
      assert html =~ "Asset updated successfully"
      assert html =~ "Updated Stock Portfolio"
    end

    test "deletes asset in listing", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      assert index_live |> element("#assets-#{asset.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#assets-#{asset.id}")
    end

    test "filters assets by type", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      # Test filtering by asset type
      assert index_live
             |> form("#filter-form", asset_type: asset.asset_type)
             |> render_submit()

      html = render(index_live)
      assert html =~ asset.asset_name
    end

    test "searches assets by name", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/assets")

      # Test searching by asset name
      assert index_live
             |> form("#search-form", search: asset.asset_name)
             |> render_submit()

      html = render(index_live)
      assert html =~ asset.asset_name
    end
  end
end
