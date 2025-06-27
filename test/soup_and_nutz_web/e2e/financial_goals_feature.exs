defmodule SoupAndNutzWeb.E2E.FinancialGoalsFeature do
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

  feature "user can create a financial goal", %{session: session} do
    # Login user
    username = "goal_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> fill_in(Query.text_field("First name"), with: "Goal")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Navigate to goals and create new goal
    session
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))
    |> click(Query.button("Add Goal"))
    |> assert_has(Query.text("Add New Goal"))
    |> fill_in(Query.text_field("Title"), with: "Emergency Fund")
    |> fill_in(Query.text_field("Target Amount"), with: "10000")
    |> fill_in(Query.text_field("Current Amount"), with: "2000")
    |> fill_in(Query.text_field("Target Date"), with: "2025-12-31")
    |> fill_in(Query.text_field("Description"), with: "Save 6 months of expenses")
    |> click(Query.button("Save Goal"))
    |> assert_has(Query.text("Goal created successfully"))
    |> assert_has(Query.text("Emergency Fund"))
  end

  feature "user can update goal progress", %{session: session} do
    # Login existing user
    username = "goal_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))

    # Update goal progress
    session
    |> click(Query.css("button[aria-label*='Update Progress']"))
    |> assert_has(Query.text("Update Goal Progress"))
    |> fill_in(Query.text_field("Current Amount"), with: "3500")
    |> click(Query.button("Update Progress"))
    |> assert_has(Query.text("Progress updated successfully"))
    |> assert_has(Query.text("35%"))
  end

  feature "user can view goal details and timeline", %{session: session} do
    # Login existing user
    username = "goal_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))

    # View goal details
    session
    |> click(Query.link("Emergency Fund"))
    |> assert_has(Query.text("Goal Details"))
    |> assert_has(Query.text("Emergency Fund"))
    |> assert_has(Query.text("$10,000.00"))
    |> assert_has(Query.text("Timeline"))
  end

  feature "user can mark goal as completed", %{session: session} do
    # Login existing user
    username = "goal_user_#{System.system_time() - 3}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))

    # Mark goal as completed
    session
    |> click(Query.css("button[aria-label*='Complete']"))
    |> assert_has(Query.text("Mark as Completed"))
    |> click(Query.button("Complete Goal"))
    |> assert_has(Query.text("Goal completed successfully"))
    |> assert_has(Query.css(".text-green-500", text: "Completed"))
  end

  feature "user can delete a goal", %{session: session} do
    # Login existing user
    username = "goal_user_#{System.system_time() - 4}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.text("Financial Goals"))

    # Delete a goal
    session
    |> click(Query.css("button[aria-label*='Delete']"))
    |> assert_has(Query.text("Are you sure"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Goal deleted successfully"))
  end
end
