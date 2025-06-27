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
    # Login user
    username = "profile_user_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/register")
    |> fill_in(Query.text_field("First name"), with: "Profile")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))

    # Navigate to profile
    session
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))
    |> assert_has(Query.text("Profile"))

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
    # Login existing user
    username = "profile_user_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))

    # Change password
    session
    |> click(Query.link("Change Password"))
    |> assert_has(Query.text("Change Password"))
    |> fill_in(Query.text_field("Current Password"), with: password)
    |> fill_in(Query.text_field("New Password"), with: "newpassword123")
    |> fill_in(Query.text_field("Confirm New Password"), with: "newpassword123")
    |> click(Query.button("Update Password"))
    |> assert_has(Query.text("Password updated successfully"))
  end

  feature "user can update financial preferences", %{session: session} do
    # Login existing user
    username = "profile_user_#{System.system_time() - 2}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))

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
    # Login existing user
    username = "profile_user_#{System.system_time() - 3}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))

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
    # Login existing user
    username = "profile_user_#{System.system_time() - 4}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))

    # Export data
    session
    |> click(Query.link("Data Export"))
    |> assert_has(Query.text("Export Your Data"))
    |> click(Query.button("Export All Data"))
    |> assert_has(Query.text("Export request submitted"))
  end

  feature "user can delete account", %{session: session} do
    # Login existing user
    username = "profile_user_#{System.system_time() - 5}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> click(Query.css("button[aria-label*='User']"))
    |> click(Query.link("Profile"))
    |> assert_has(Query.text("Profile Settings"))

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
