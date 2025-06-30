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

  @tag :skip
  feature "user can add income transaction", %{session: session} do
    # Create a user for this test
    username = "income#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Income",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and navigate to cash flows
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.css("h1", text: "Cash Flows"))
    |> click(Query.link("New Cash Flow"))
    |> assert_has(Query.css("h2", text: "New Cash Flow"))
    |> fill_in(Query.text_field("Description"), with: "Salary Payment")
    |> fill_in(Query.text_field("Amount"), with: "5000")
    |> fill_in(Query.text_field("Transaction type"), with: "Income")
    |> fill_in(Query.text_field("Category"), with: "Salary")
    |> fill_in(Query.text_field("Currency code"), with: "USD")
    |> fill_in(Query.text_field("Transaction date"), with: "2024-01-15")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Cash flow created successfully"))
    |> assert_has(Query.text("Salary Payment"))
  end

  @tag :skip
  feature "user can add expense transaction", %{session: session} do
    # Create a user for this test
    username = "expense#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Expense",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and add expense
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> click(Query.link("New Cash Flow"))
    |> fill_in(Query.text_field("Description"), with: "Grocery Shopping")
    |> fill_in(Query.text_field("Amount"), with: "150")
    |> fill_in(Query.text_field("Transaction type"), with: "Expense")
    |> fill_in(Query.text_field("Category"), with: "Food")
    |> fill_in(Query.text_field("Currency code"), with: "USD")
    |> fill_in(Query.text_field("Transaction date"), with: "2024-01-15")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Cash flow created successfully"))
    |> assert_has(Query.text("Grocery Shopping"))
  end

  feature "user can view cash flow details", %{session: session} do
    # Create a user and cash flow for this test
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

    # Create a cash flow directly in the database
    cash_flow_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_VIEW_#{System.system_time()}",
      cash_flow_name: "Test Transaction",
      cash_flow_type: "Income",
      cash_flow_category: "Salary",
      currency_code: "USD",
      amount: Decimal.new("1000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, cash_flow} = SoupAndNutz.FinancialInstruments.create_cash_flow(cash_flow_params)

    # Login and view the cash flow
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> click(Query.link("Test Transaction"))
    |> assert_has(Query.css("h1", text: "Cash Flow Details"))
    |> assert_has(Query.text("Test Transaction"))
    |> assert_has(Query.text("Income"))
    |> assert_has(Query.text("Salary"))
    |> assert_has(Query.text("$1,000"))
  end

  @tag :skip
  feature "user can edit cash flow", %{session: session} do
    # Create a user and cash flow for this test
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

    # Create a cash flow directly in the database
    cash_flow_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_EDIT_#{System.system_time()}",
      cash_flow_name: "Original Transaction",
      cash_flow_type: "Income",
      cash_flow_category: "Salary",
      currency_code: "USD",
      amount: Decimal.new("1000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, cash_flow} = SoupAndNutz.FinancialInstruments.create_cash_flow(cash_flow_params)

    # Login and edit the cash flow
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> click(Query.link("Original Transaction"))
    |> click(Query.link("Edit"))
    |> assert_has(Query.css("h2", text: "Edit Cash Flow"))
    |> fill_in(Query.text_field("Description"), with: "Updated Transaction")
    |> fill_in(Query.text_field("Amount"), with: "1200")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Cash flow updated successfully"))
    |> assert_has(Query.text("Updated Transaction"))
    |> assert_has(Query.text("$1,200"))
  end

  feature "user can delete cash flow", %{session: session} do
    # Create a user and cash flow for this test
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

    # Create a cash flow directly in the database
    cash_flow_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_DELETE_#{System.system_time()}",
      cash_flow_name: "Transaction to Delete",
      cash_flow_type: "Income",
      cash_flow_category: "Salary",
      currency_code: "USD",
      amount: Decimal.new("1000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, cash_flow} = SoupAndNutz.FinancialInstruments.create_cash_flow(cash_flow_params)

    # Login and delete the cash flow
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> click(Query.link("Transaction to Delete"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Cash flow deleted successfully"))
    |> refute_has(Query.text("Transaction to Delete"))
  end

  feature "user can view cash flow summary", %{session: session} do
    # Create a user and multiple cash flows for this test
    username = "summary#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Summary",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create cash flows directly in the database
    income_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_INCOME_#{System.system_time()}",
      cash_flow_name: "Salary",
      cash_flow_type: "Income",
      cash_flow_category: "Salary",
      currency_code: "USD",
      amount: Decimal.new("5000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    expense_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_EXPENSE_#{System.system_time()}",
      cash_flow_name: "Rent",
      cash_flow_type: "Expense",
      cash_flow_category: "Housing",
      currency_code: "USD",
      amount: Decimal.new("2000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, _income} = SoupAndNutz.FinancialInstruments.create_cash_flow(income_params)
    {:ok, _expense} = SoupAndNutz.FinancialInstruments.create_cash_flow(expense_params)

    # Login and view cash flow summary
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flows"))
    |> assert_has(Query.text("Salary"))
    |> assert_has(Query.text("Rent"))
    |> assert_has(Query.text("$5,000"))
    |> assert_has(Query.text("$2,000"))
  end
end
