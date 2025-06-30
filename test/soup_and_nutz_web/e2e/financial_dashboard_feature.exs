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
    # Create a user for this test
    username = "dashboard#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Dashboard",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and view dashboard
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("Dashboard"))
    |> assert_has(Query.text("Assets"))
    |> assert_has(Query.text("Debts"))
    |> assert_has(Query.text("Cash Flow"))
  end

  feature "dashboard shows correct financial summary", %{session: session} do
    # Create a user with financial data for this test
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

    # Create assets, debts, and cash flows directly in the database
    asset_params = %{
      user_id: user.id,
      asset_identifier: "ASSET_DASHBOARD_#{System.system_time()}",
      asset_name: "Test Asset",
      asset_type: "InvestmentSecurities",
      currency_code: "USD",
      fair_value: Decimal.new("10500"),
      book_value: Decimal.new("10000"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    debt_params = %{
      user_id: user.id,
      debt_identifier: "DEBT_DASHBOARD_#{System.system_time()}",
      debt_name: "Test Debt",
      debt_type: "PersonalLoan",
      currency_code: "USD",
      principal_amount: Decimal.new("5000"),
      outstanding_balance: Decimal.new("4800"),
      interest_rate: Decimal.new("12.5"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    cash_flow_params = %{
      user_id: user.id,
      cash_flow_identifier: "CF_DASHBOARD_#{System.system_time()}",
      cash_flow_name: "Test Income",
      cash_flow_type: "Income",
      cash_flow_category: "Salary",
      currency_code: "USD",
      amount: Decimal.new("3000"),
      transaction_date: ~D[2024-01-15],
      effective_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, _asset} = SoupAndNutz.FinancialInstruments.create_asset(asset_params)
    {:ok, _debt} = SoupAndNutz.FinancialInstruments.create_debt_obligation(debt_params)
    {:ok, _cash_flow} = SoupAndNutz.FinancialInstruments.create_cash_flow(cash_flow_params)

    # Login and check dashboard summary
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("$10,500"))
    |> assert_has(Query.text("$4,800"))
    |> assert_has(Query.text("$5,700"))
    |> assert_has(Query.text("Test Asset"))
    |> assert_has(Query.text("Test Debt"))
  end

  feature "user can navigate dashboard sections", %{session: session} do
    # Create a user for this test
    username = "navigate#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Navigate",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test navigation
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Assets"))
    |> assert_has(Query.css("h1", text: "Assets"))
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.css("h1", text: "Debt Obligations"))
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.css("h1", text: "Cash Flows"))
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
  end

  feature "user can access planning tools", %{session: session} do
    # Create a user for this test
    username = "planning#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Planning",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test planning tools access
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Budget Planner"))
    |> assert_has(Query.text("Budget"))
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Debt Payoff"))
    |> assert_has(Query.text("Debt Payoff"))
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
  end

  feature "user can view and edit profile", %{session: session} do
    # Create a user for this test
    username = "profile#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Profile",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test profile access
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> visit("/auth/profile")
    |> assert_has(Query.css("h1", text: "Profile Settings"))
    |> assert_has(Query.text("Profile"))
    |> assert_has(Query.text("User"))
  end

  feature "user can change password", %{session: session} do
    # Create a user for this test
    username = "password#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Password",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test password change
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> visit("/auth/change_password")
    |> assert_has(Query.css("h1", text: "Change Password"))
    |> fill_in(Query.text_field("New Password"), with: "newpassword123")
    |> fill_in(Query.text_field("Confirm New Password"), with: "newpassword123")
    |> click(Query.button("Update Password"))
    |> assert_has(Query.text("Password updated successfully"))
  end
end
