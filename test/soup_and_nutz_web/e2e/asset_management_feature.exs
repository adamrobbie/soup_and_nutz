defmodule SoupAndNutzWeb.E2E.AssetManagementFeature do
  use ExUnit.Case, async: false
  use Wallaby.DSL

  import Wallaby.Feature
  import SoupAndNutz.DataCase

  setup do
    # Set up Ecto sandbox for Wallaby tests
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SoupAndNutz.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(SoupAndNutz.Repo, {:shared, self()})

    {:ok, session} = Wallaby.start_session()
    {:ok, session: session}
  end

  @tag :skip
  feature "user can add a new asset", %{session: session} do
    # Create a user for this test
    username = "asset#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Asset",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and navigate to assets
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Assets"))
    |> assert_has(Query.css("h1", text: "Assets"))
    |> click(Query.link("New Asset"))
    |> assert_has(Query.css("h1", text: "New Asset"))
    |> fill_in(Query.text_field("Asset identifier"), with: "TEST_ASSET_001")
    |> fill_in(Query.text_field("Asset name"), with: "Test Investment")
    |> fill_in(Query.css("select[name='asset[asset_type]']"), with: "InvestmentSecurities")
    |> fill_in(Query.text_field("Currency code"), with: "USD")
    |> fill_in(Query.text_field("Measurement date"), with: "2024-01-15")
    |> fill_in(Query.text_field("Reporting period"), with: "2024-01")
    |> fill_in(Query.css("select[name='asset[risk_level]']"), with: "Medium")
    |> fill_in(Query.css("select[name='asset[liquidity_level]']"), with: "High")
    |> fill_in(Query.css("select[name='asset[validation_status]']"), with: "Pending")
    |> click(Query.button("Save Asset"))
    |> assert_has(Query.text("Asset created successfully"))
    |> take_screenshot(name: "user_can_add_a_new_asset_debug.png")
    |> assert_has(Query.css(".phx-error, .invalid-feedback, .help-block, .alert-danger"))
  end

  feature "user can view asset details", %{session: session} do
    # Create a user and asset for this test
    username = "view#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "View",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create an asset directly in the database
    asset_params = %{
      user_id: user.id,
      asset_identifier: "ASSET_VIEW_#{System.system_time()}",
      asset_name: "Test Asset",
      asset_type: "InvestmentSecurities",
      currency_code: "USD",
      fair_value: Decimal.new("10500"),
      book_value: Decimal.new("10000"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, asset} = SoupAndNutz.FinancialInstruments.create_asset(asset_params)

    # Login and view the asset
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> click(Query.link("Test Asset"))
    |> assert_has(Query.css("h1", text: "Asset Details"))
    |> assert_has(Query.text("Test Asset"))
    |> assert_has(Query.text("Investment"))
    |> assert_has(Query.text("$10,000"))
    |> assert_has(Query.text("$10,500"))
  end

  @tag :skip
  feature "user can edit an existing asset", %{session: session} do
    # Create a user and asset for this test
    username = "edit#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Edit",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create an asset directly in the database
    asset_params = %{
      user_id: user.id,
      asset_identifier: "ASSET_EDIT_#{System.system_time()}",
      asset_name: "Original Asset",
      asset_type: "InvestmentSecurities",
      currency_code: "USD",
      fair_value: Decimal.new("10500"),
      book_value: Decimal.new("10000"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, asset} = SoupAndNutz.FinancialInstruments.create_asset(asset_params)

    # Login and edit the asset
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> click(Query.link("Original Asset"))
    |> click(Query.link("Edit"))
    |> assert_has(Query.css("h2", text: "Edit Asset"))
    |> fill_in(Query.text_field("Asset name"), with: "Updated Asset")
    |> fill_in(Query.text_field("Fair value"), with: "11000")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Asset updated successfully"))
    |> assert_has(Query.text("Updated Asset"))
    |> assert_has(Query.text("$11,000"))
  end

  feature "user can delete an asset", %{session: session} do
    # Create a user and asset for this test
    username = "delete#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Delete",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create an asset directly in the database
    asset_params = %{
      user_id: user.id,
      asset_identifier: "ASSET_DELETE_#{System.system_time()}",
      asset_name: "Asset to Delete",
      asset_type: "InvestmentSecurities",
      currency_code: "USD",
      fair_value: Decimal.new("10500"),
      book_value: Decimal.new("10000"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, asset} = SoupAndNutz.FinancialInstruments.create_asset(asset_params)

    # Login and delete the asset
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> click(Query.link("Asset to Delete"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Asset deleted successfully"))
    |> refute_has(Query.text("Asset to Delete"))
  end
end
