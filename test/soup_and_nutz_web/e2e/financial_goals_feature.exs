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

  @tag :skip
  feature "user can create a financial goal", %{session: session} do
    # Create a user for this test
    username = "goal#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Goal",
      "last_name" => "User"
    }

    {:ok, _user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and navigate to goals
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.link("Goals"))
    |> assert_has(Query.css("h1", text: "Financial Goals"))
    |> click(Query.link("New Financial Goal"))
    |> assert_has(Query.css("h2", text: "New Financial Goal"))
    |> fill_in(Query.text_field("Goal name"), with: "Emergency Fund")
    |> fill_in(Query.text_field("Goal type"), with: "Savings")
    |> fill_in(Query.text_field("Target amount"), with: "10000")
    |> fill_in(Query.text_field("Current amount"), with: "2000")
    |> fill_in(Query.text_field("Target date"), with: "2024-12-31")
    |> fill_in(Query.text_field("Priority level"), with: "High")
    |> fill_in(Query.text_field("Currency code"), with: "USD")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Financial goal created successfully"))
    |> assert_has(Query.text("Emergency Fund"))
  end

  feature "user can view goal details and timeline", %{session: session} do
    # Create a user and goal for this test
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

    # Create a goal directly in the database
    goal_params = %{
      user_id: user.id,
      goal_identifier: "GOAL_VIEW_#{System.system_time()}",
      goal_name: "Test Goal",
      goal_type: "Savings",
      target_amount: Decimal.new("10000"),
      current_amount: Decimal.new("2000"),
      target_date: ~D[2024-12-31],
      start_date: ~D[2024-01-01],
      priority_level: "High"
    }

    {:ok, goal} = SoupAndNutz.FinancialGoals.create_financial_goal(goal_params)

    # Login and view the goal
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> click(Query.link("Test Goal"))
    |> assert_has(Query.css("h1", text: "Financial Goal Details"))
    |> assert_has(Query.text("Test Goal"))
    |> assert_has(Query.text("Savings"))
    |> assert_has(Query.text("$10,000"))
    |> assert_has(Query.text("$2,000"))
    |> assert_has(Query.text("High"))
  end

  feature "user can update goal progress", %{session: session} do
    # Create a user and goal for this test
    username = "progress#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Progress",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create a goal directly in the database
    goal_params = %{
      user_id: user.id,
      goal_identifier: "GOAL_PROGRESS_#{System.system_time()}",
      goal_name: "Progress Goal",
      goal_type: "Savings",
      target_amount: Decimal.new("10000"),
      current_amount: Decimal.new("2000"),
      target_date: ~D[2024-12-31],
      start_date: ~D[2024-01-01],
      priority_level: "High"
    }

    {:ok, goal} = SoupAndNutz.FinancialGoals.create_financial_goal(goal_params)

    # Login and update goal progress
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> click(Query.link("Progress Goal"))
    |> click(Query.link("Edit"))
    |> assert_has(Query.css("h2", text: "Edit Financial Goal"))
    |> fill_in(Query.text_field("Current amount"), with: "3500")
    |> click(Query.button("Save"))
    |> assert_has(Query.text("Financial goal updated successfully"))
    |> assert_has(Query.text("$3,500"))
  end

  feature "user can mark goal as completed", %{session: session} do
    # Create a user and goal for this test
    username = "complete#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Complete",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Create a goal directly in the database
    goal_params = %{
      user_id: user.id,
      goal_identifier: "GOAL_COMPLETE_#{System.system_time()}",
      goal_name: "Goal to Complete",
      goal_type: "Savings",
      target_amount: Decimal.new("10000"),
      current_amount: Decimal.new("10000"),
      target_date: ~D[2024-12-31],
      start_date: ~D[2024-01-01],
      priority_level: "High"
    }

    {:ok, goal} = SoupAndNutz.FinancialGoals.create_financial_goal(goal_params)

    # Login and mark goal as completed
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> click(Query.link("Goal to Complete"))
    |> click(Query.button("Mark as Completed"))
    |> assert_has(Query.text("Goal marked as completed"))
    |> assert_has(Query.text("Completed"))
  end

  feature "user can delete a goal", %{session: session} do
    # Create a user and goal for this test
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

    # Create a goal directly in the database
    goal_params = %{
      user_id: user.id,
      goal_identifier: "GOAL_DELETE_#{System.system_time()}",
      goal_name: "Goal to Delete",
      goal_type: "Savings",
      target_amount: Decimal.new("10000"),
      current_amount: Decimal.new("2000"),
      target_date: ~D[2024-12-31],
      start_date: ~D[2024-01-01],
      priority_level: "High"
    }

    {:ok, goal} = SoupAndNutz.FinancialGoals.create_financial_goal(goal_params)

    # Login and delete the goal
    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.link("Goals"))
    |> click(Query.link("Goal to Delete"))
    |> click(Query.button("Delete"))
    |> assert_has(Query.text("Financial goal deleted successfully"))
    |> refute_has(Query.text("Goal to Delete"))
  end

  @tag :skip
  feature "user can edit a goal", %{session: session} do
    # ... existing code ...
  end
end
