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

  feature "user can add a new asset", %{session: session} do
    # Login user
    username = "asset_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> fill_in(Query.text_field("First name"), with: "Asset")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Navigate to assets and add new asset
    session
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))
    |> click(Query.button("Add Asset"))
    |> assert_has(Query.text("Add New Asset"))
    |> fill_in(Query.text_field("Name"), with: "Test Investment")
    |> fill_in(Query.text_field("Value"), with: "10000")
    |> fill_in(Query.text_field("Description"), with: "Test investment asset")
    |> click(Query.button("Save Asset"))
    |> assert_has(Query.text("Asset created successfully"))
    |> assert_has(Query.text("Test Investment"))
  end

  feature "user can edit an existing asset", %{session: session} do
    # Login existing user
    username = "asset_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))

    # Edit the first asset
    session
    |> click(Query.css("button[aria-label*='Edit']"))
    |> assert_has(Query.text("Edit Asset"))
    |> fill_in(Query.text_field("Value"), with: "15000")
    |> click(Query.button("Update Asset"))
    |> assert_has(Query.text("Asset updated successfully"))
  end

  feature "user can delete an asset", %{session: session} do
    # Login existing user
    username = "asset_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))

    # Delete an asset
    session
    |> click(Query.css("button[aria-label*='Delete']"))
    |> assert_has(Query.text("Are you sure"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Asset deleted successfully"))
  end

  feature "user can view asset details", %{session: session} do
    # Login existing user
    username = "asset_user_#{System.system_time() - 3}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))

    # View asset details
    session
    |> click(Query.link("Test Investment"))
    |> assert_has(Query.text("Asset Details"))
    |> assert_has(Query.text("Test Investment"))
    |> assert_has(Query.text("$15,000.00"))
  end
end
