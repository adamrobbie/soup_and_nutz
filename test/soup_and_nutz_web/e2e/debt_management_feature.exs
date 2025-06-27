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

  feature "user can add a new debt", %{session: session} do
    # Login user
    username = "debt_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> fill_in(Query.text_field("First name"), with: "Debt")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Navigate to debts and add new debt
    session
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))
    |> click(Query.button("Add Debt"))
    |> assert_has(Query.text("Add New Debt"))
    |> fill_in(Query.text_field("Name"), with: "Test Credit Card")
    |> fill_in(Query.text_field("Balance"), with: "5000")
    |> fill_in(Query.text_field("Interest Rate"), with: "18.99")
    |> fill_in(Query.text_field("Minimum Payment"), with: "150")
    |> click(Query.button("Save Debt"))
    |> assert_has(Query.text("Debt created successfully"))
    |> assert_has(Query.text("Test Credit Card"))
  end

  feature "user can edit an existing debt", %{session: session} do
    # Login existing user
    username = "debt_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))

    # Edit the first debt
    session
    |> click(Query.css("button[aria-label*='Edit']"))
    |> assert_has(Query.text("Edit Debt"))
    |> fill_in(Query.text_field("Balance"), with: "4500")
    |> click(Query.button("Update Debt"))
    |> assert_has(Query.text("Debt updated successfully"))
  end

  feature "user can view debt payoff plan", %{session: session} do
    # Login existing user
    username = "debt_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))

    # View debt payoff plan
    session
    |> click(Query.button("View Payoff Plan"))
    |> assert_has(Query.text("Debt Payoff Plan"))
    |> assert_has(Query.text("Avalanche Method"))
    |> assert_has(Query.text("Snowball Method"))
  end

  feature "user can delete a debt", %{session: session} do
    # Login existing user
    username = "debt_user_#{System.system_time() - 3}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))

    # Delete a debt
    session
    |> click(Query.css("button[aria-label*='Delete']"))
    |> assert_has(Query.text("Are you sure"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Debt deleted successfully"))
  end
end
