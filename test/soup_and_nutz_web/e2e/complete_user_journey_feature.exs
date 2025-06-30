defmodule SoupAndNutzWeb.E2E.CompleteUserJourneyFeature do
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

  feature "complete financial planning journey", %{session: session} do
    # Create a user for this test
    username = "journey#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Journey",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and complete the journey
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))

    # Step 2: View empty dashboard
    session
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("Total Assets"))
    |> assert_has(Query.text("Total Debt"))
    |> assert_has(Query.text("Net Worth"))

    # Step 3: Add assets
    session
    |> click(Query.link("Assets"))
    |> assert_has(Query.text("Assets"))
    |> click(Query.button("Add Asset"))
    |> fill_in(Query.text_field("Name"), with: "Savings Account")
    |> fill_in(Query.text_field("Value"), with: "15000")
    |> fill_in(Query.text_field("Description"), with: "Emergency fund")
    |> click(Query.button("Save Asset"))
    |> assert_has(Query.text("Asset created successfully"))

    # Add another asset
    session
    |> click(Query.button("Add Asset"))
    |> fill_in(Query.text_field("Name"), with: "Investment Portfolio")
    |> fill_in(Query.text_field("Value"), with: "25000")
    |> fill_in(Query.text_field("Description"), with: "401k and IRA")
    |> click(Query.button("Save Asset"))
    |> assert_has(Query.text("Asset created successfully"))

    # Step 4: Add debts
    session
    |> click(Query.link("Debts"))
    |> assert_has(Query.text("Debts"))
    |> click(Query.button("Add Debt"))
    |> fill_in(Query.text_field("Name"), with: "Student Loan")
    |> fill_in(Query.text_field("Balance"), with: "20000")
    |> fill_in(Query.text_field("Interest Rate"), with: "5.5")
    |> fill_in(Query.text_field("Minimum Payment"), with: "200")
    |> click(Query.button("Save Debt"))
    |> assert_has(Query.text("Debt created successfully"))

    # Add another debt
    session
    |> click(Query.button("Add Debt"))
    |> fill_in(Query.text_field("Name"), with: "Credit Card")
    |> fill_in(Query.text_field("Balance"), with: "3000")
    |> fill_in(Query.text_field("Interest Rate"), with: "18.99")
    |> fill_in(Query.text_field("Minimum Payment"), with: "100")
    |> click(Query.button("Save Debt"))
    |> assert_has(Query.text("Debt created successfully"))

    # Step 5: Add cash flow
    session
    |> click(Query.link("Cash Flow"))
    |> assert_has(Query.text("Cash Flow"))
    |> click(Query.button("Add Income"))
    |> fill_in(Query.text_field("Description"), with: "Monthly Salary")
    |> fill_in(Query.text_field("Amount"), with: "6000")
    |> fill_in(Query.text_field("Category"), with: "Employment")
    |> fill_in(Query.text_field("Date"), with: "2024-01-15")
    |> click(Query.button("Save Income"))
    |> assert_has(Query.text("Income added successfully"))

    # Add expenses
    session
    |> click(Query.button("Add Expense"))
    |> fill_in(Query.text_field("Description"), with: "Rent")
    |> fill_in(Query.text_field("Amount"), with: "2000")
    |> fill_in(Query.text_field("Category"), with: "Housing")
    |> fill_in(Query.text_field("Date"), with: "2024-01-01")
    |> click(Query.button("Save Expense"))
    |> assert_has(Query.text("Expense added successfully"))

    session
    |> click(Query.button("Add Expense"))
    |> fill_in(Query.text_field("Description"), with: "Groceries")
    |> fill_in(Query.text_field("Amount"), with: "400")
    |> fill_in(Query.text_field("Category"), with: "Food")
    |> fill_in(Query.text_field("Date"), with: "2024-01-15")
    |> click(Query.button("Save Expense"))
    |> assert_has(Query.text("Expense added successfully"))

    # Step 6: Create financial goals
    session
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))
    |> click(Query.button("Add Goal"))
    |> fill_in(Query.text_field("Title"), with: "Emergency Fund")
    |> fill_in(Query.text_field("Target Amount"), with: "20000")
    |> fill_in(Query.text_field("Current Amount"), with: "15000")
    |> fill_in(Query.text_field("Target Date"), with: "2024-12-31")
    |> fill_in(Query.text_field("Description"), with: "6 months of expenses")
    |> click(Query.button("Save Goal"))
    |> assert_has(Query.text("Goal created successfully"))

    # Add another goal
    session
    |> click(Query.button("Add Goal"))
    |> fill_in(Query.text_field("Title"), with: "Pay Off Student Loan")
    |> fill_in(Query.text_field("Target Amount"), with: "20000")
    |> fill_in(Query.text_field("Current Amount"), with: "0")
    |> fill_in(Query.text_field("Target Date"), with: "2026-12-31")
    |> fill_in(Query.text_field("Description"), with: "Eliminate student debt")
    |> click(Query.button("Save Goal"))
    |> assert_has(Query.text("Goal created successfully"))

    # Step 7: View updated dashboard
    session
    |> click(Query.link("Dashboard"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("$40,000.00")) # Total Assets
    |> assert_has(Query.text("$23,000.00")) # Total Debt
    |> assert_has(Query.text("$17,000.00")) # Net Worth

    # Step 8: View debt payoff plan
    session
    |> click(Query.link("Debts"))
    |> click(Query.button("View Payoff Plan"))
    |> assert_has(Query.text("Debt Payoff Plan"))
    |> assert_has(Query.text("Avalanche Method"))
    |> assert_has(Query.text("Snowball Method"))

    # Step 9: Update profile
    session
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))
    |> click(Query.button("Edit Profile"))
    |> fill_in(Query.text_field("Phone Number"), with: "555-123-4567")
    |> fill_in(Query.text_field("Timezone"), with: "America/New_York")
    |> click(Query.button("Update Profile"))
    |> assert_has(Query.text("Profile updated successfully"))

    # Step 10: Logout and verify
    session
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Sign Out"))
    |> assert_has(Query.text("Signed out successfully"))
    |> assert_has(Query.css("span", text: "Soup & Nutz"))
  end
end
