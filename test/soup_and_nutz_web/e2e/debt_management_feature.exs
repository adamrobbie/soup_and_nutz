defmodule SoupAndNutzWeb.E2E.DebtManagementFeature do
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
  feature "user can add a new debt", %{session: session} do
    # Create a user for this test
    username = "debt#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Debt",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and navigate to debts
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.css("h1", text: "Debt Obligations"))
    |> click(Query.link("New Debt Obligation"))
    |> assert_has(Query.css("h2", text: "New Debt Obligation"))
    |> fill_in(Query.text_field("Debt name"), with: "Test Credit Card")
    |> fill_in(Query.text_field("Debt type"), with: "Credit Card")
    |> fill_in(Query.text_field("Principal amount"), with: "5000")
    |> fill_in(Query.text_field("Outstanding balance"), with: "4800")
    |> fill_in(Query.text_field("Interest rate"), with: "18.5")
    |> fill_in(Query.text_field("Currency code"), with: "USD")
    |> fill_in(Query.text_field("Risk level"), with: "High")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Debt obligation created successfully"))
    |> assert_has(Query.text("Test Credit Card"))
  end

  feature "user can view debt details", %{session: session} do
    # Create a user and debt for this test
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

    # Create a debt directly in the database
    debt_params = %{
      user_id: user.id,
      debt_identifier: "DEBT_VIEW_#{System.system_time()}",
      debt_name: "Test Loan",
      debt_type: "PersonalLoan",
      currency_code: "USD",
      principal_amount: Decimal.new("10000"),
      outstanding_balance: Decimal.new("9500"),
      interest_rate: Decimal.new("12.5"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, debt} = SoupAndNutz.FinancialInstruments.create_debt_obligation(debt_params)

    # Login and view the debt
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> click(Query.link("Test Loan"))
    |> assert_has(Query.css("h1", text: "Debt Obligation Details"))
    |> assert_has(Query.text("Test Loan"))
    |> assert_has(Query.text("Personal Loan"))
    |> assert_has(Query.text("$10,000"))
    |> assert_has(Query.text("$9,500"))
    |> assert_has(Query.text("12.5%"))
  end

  @tag :skip
  feature "user can edit an existing debt", %{session: session} do
    # Create a user and debt for this test
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

    # Create a debt directly in the database
    debt_params = %{
      user_id: user.id,
      debt_identifier: "DEBT_EDIT_#{System.system_time()}",
      debt_name: "Original Loan",
      debt_type: "PersonalLoan",
      currency_code: "USD",
      principal_amount: Decimal.new("10000"),
      outstanding_balance: Decimal.new("9500"),
      interest_rate: Decimal.new("12.5"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, debt} = SoupAndNutz.FinancialInstruments.create_debt_obligation(debt_params)

    # Login and edit the debt
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> click(Query.link("Original Loan"))
    |> click(Query.link("Edit"))
    |> assert_has(Query.css("h2", text: "Edit Debt Obligation"))
    |> fill_in(Query.text_field("Debt name"), with: "Updated Loan")
    |> fill_in(Query.text_field("Outstanding balance"), with: "9000")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Debt obligation updated successfully"))
    |> assert_has(Query.text("Updated Loan"))
    |> assert_has(Query.text("$9,000"))
  end

  feature "user can delete a debt", %{session: session} do
    # Create a user and debt for this test
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

    # Create a debt directly in the database
    debt_params = %{
      user_id: user.id,
      debt_identifier: "DEBT_DELETE_#{System.system_time()}",
      debt_name: "Debt to Delete",
      debt_type: "PersonalLoan",
      currency_code: "USD",
      principal_amount: Decimal.new("10000"),
      outstanding_balance: Decimal.new("9500"),
      interest_rate: Decimal.new("12.5"),
      risk_level: "Medium",
      measurement_date: ~D[2024-01-15],
      reporting_period: "2024-01"
    }

    {:ok, debt} = SoupAndNutz.FinancialInstruments.create_debt_obligation(debt_params)

    # Login and delete the debt
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> click(Query.link("Debt to Delete"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Debt obligation deleted successfully"))
    |> refute_has(Query.text("Debt to Delete"))
  end
end
