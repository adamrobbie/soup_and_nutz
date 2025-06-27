defmodule SoupAndNutzWeb.E2E.CashFlowFeature do
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

  feature "user can add income transaction", %{session: session} do
    # Login user
    username = "cashflow_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> fill_in(Query.text_field("First name"), with: "CashFlow")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Navigate to cash flow and add income
    session
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))
    |> click(Query.button("Add Income"))
    |> assert_has(Query.text("Add Income"))
    |> fill_in(Query.text_field("Description"), with: "Salary")
    |> fill_in(Query.text_field("Amount"), with: "5000")
    |> fill_in(Query.text_field("Category"), with: "Employment")
    |> fill_in(Query.text_field("Date"), with: "2024-01-15")
    |> click(Query.button("Save Income"))
    |> assert_has(Query.text("Income added successfully"))
    |> assert_has(Query.text("Salary"))
  end

  feature "user can add expense transaction", %{session: session} do
    # Login existing user
    username = "cashflow_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))

    # Add expense
    session
    |> click(Query.button("Add Expense"))
    |> assert_has(Query.text("Add Expense"))
    |> fill_in(Query.text_field("Description"), with: "Groceries")
    |> fill_in(Query.text_field("Amount"), with: "200")
    |> fill_in(Query.text_field("Category"), with: "Food")
    |> fill_in(Query.text_field("Date"), with: "2024-01-15")
    |> click(Query.button("Save Expense"))
    |> assert_has(Query.text("Expense added successfully"))
    |> assert_has(Query.text("Groceries"))
  end

  feature "user can view cash flow summary", %{session: session} do
    # Login existing user
    username = "cashflow_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))

    # View summary
    session
    |> assert_has(Query.text("Total Income"))
    |> assert_has(Query.text("Total Expenses"))
    |> assert_has(Query.text("Net Cash Flow"))
    |> assert_has(Query.text("Monthly Summary"))
  end

  feature "user can filter transactions by date range", %{session: session} do
    # Login existing user
    username = "cashflow_user_#{System.system_time() - 3}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))

    # Filter by date range
    session
    |> click(Query.button("Filter"))
    |> fill_in(Query.text_field("Start Date"), with: "2024-01-01")
    |> fill_in(Query.text_field("End Date"), with: "2024-01-31")
    |> click(Query.button("Apply Filter"))
    |> assert_has(Query.text("Filtered Results"))
  end

  feature "user can categorize transactions", %{session: session} do
    # Login existing user
    username = "cashflow_user_#{System.system_time() - 4}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))

    # View categories
    session
    |> click(Query.link("Categories"))
    |> assert_has(Query.text("Transaction Categories"))
    |> assert_has(Query.text("Employment"))
    |> assert_has(Query.text("Food"))
  end

  feature "user can export cash flow data", %{session: session} do
    # Login existing user
    username = "cashflow_user_#{System.system_time() - 5}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))

    # Export data
    session
    |> click(Query.button("Export"))
    |> assert_has(Query.text("Export Options"))
    |> click(Query.button("Export CSV"))
    |> assert_has(Query.text("Export completed"))
  end
end
