defmodule SoupAndNutzWeb.E2E.UserProfileFeature do
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

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

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

    # Edit profile
    session
    |> click(Query.button("Edit Profile"))
    |> fill_in(Query.text_field("Phone Number"), with: "555-123-4567")
    |> fill_in(Query.text_field("Timezone"), with: "America/New_York")
    |> fill_in(Query.text_field("Preferred Currency"), with: "USD")
    |> click(Query.button("Update Profile"))
    |> assert_has(Query.text("Profile updated successfully"))
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

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

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

  feature "user can update financial preferences", %{session: session} do
    # Create a user for this test
    username = "preferences#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Preferences",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test preferences
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

    # Update financial preferences
    session
    |> click(Query.link("Financial Preferences"))
    |> assert_has(Query.text("Financial Preferences"))
    |> fill_in(Query.text_field("Risk Tolerance"), with: "Conservative")
    |> fill_in(Query.text_field("Investment Horizon"), with: "Medium Term")
    |> fill_in(Query.text_field("Default Reporting Period"), with: "Monthly")
    |> click(Query.button("Save Preferences"))
    |> assert_has(Query.text("Preferences updated successfully"))
  end

  feature "user can manage notification settings", %{session: session} do
    # Create a user for this test
    username = "notifications#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Notifications",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test notification settings
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

    # Manage notifications
    session
    |> click(Query.link("Notifications"))
    |> assert_has(Query.text("Notification Settings"))
    |> click(Query.checkbox("Email Notifications"))
    |> click(Query.checkbox("Goal Reminders"))
    |> click(Query.checkbox("Bill Due Alerts"))
    |> click(Query.button("Save Settings"))
    |> assert_has(Query.text("Notification settings updated"))
  end

  feature "user can export personal data", %{session: session} do
    # Create a user for this test
    username = "export#{System.system_time() |> rem(10000)}"
    email = "#{username}@example.com"
    password = "password123"

    user_params = %{
      "email" => email,
      "username" => username,
      "password" => password,
      "password_confirmation" => password,
      "first_name" => "Export",
      "last_name" => "User"
    }

    {:ok, user} = SoupAndNutz.Accounts.create_user(user_params)

    # Login and test data export
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

    # Export data
    session
    |> click(Query.link("Data Export"))
    |> assert_has(Query.text("Export Your Data"))
    |> click(Query.button("Export All Data"))
    |> assert_has(Query.text("Export request submitted"))
  end

  feature "user can delete account", %{session: session} do
    # Create a user for this test
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

    # Login and test account deletion
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

    # Delete account
    session
    |> click(Query.link("Delete Account"))
    |> assert_has(Query.text("Delete Account"))
    |> fill_in(Query.text_field("Confirm Password"), with: password)
    |> fill_in(Query.text_field("Type 'DELETE' to confirm"), with: "DELETE")
    |> click(Query.button("Delete Account"))
    |> assert_has(Query.text("Account deleted successfully"))
  end
end
