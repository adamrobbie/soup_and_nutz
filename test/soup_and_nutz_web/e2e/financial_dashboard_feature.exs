defmodule SoupAndNutzWeb.E2E.FinancialDashboardFeature do
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

  feature "user can view financial dashboard", %{session: session} do
    # First create and login a user
    username = "dashboard_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> assert_has(Query.css("h2", text: "Create your account"))
    |> fill_in(Query.text_field("First name"), with: "Dashboard")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Now verify dashboard elements
    session
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("Total Assets"))
    |> assert_has(Query.text("Total Debt"))
    |> assert_has(Query.text("Net Worth"))
    |> assert_has(Query.text("Debt/Asset Ratio"))
  end

  feature "user can navigate dashboard sections", %{session: session} do
    # Login existing user
    username = "dashboard_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> assert_has(Query.css("h2", text: "Sign in to your account"))
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))

    # Test navigation to different sections
    session
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))
  end

  feature "dashboard shows correct financial summary", %{session: session} do
    # Login existing user
    username = "dashboard_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> assert_has(Query.css("h2", text: "Sign in to your account"))
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))

    # Verify summary cards are present
    session
    |> assert_has(Query.css(".bg-gray-900", text: "Total Assets"))
    |> assert_has(Query.css(".bg-gray-900", text: "Total Debt"))
    |> assert_has(Query.css(".bg-gray-900", text: "Net Worth"))
    |> assert_has(Query.css(".bg-gray-900", text: "Debt/Asset Ratio"))
  end
end
