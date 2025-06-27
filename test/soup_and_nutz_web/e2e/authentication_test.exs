defmodule SoupAndNutzWeb.E2E.AuthenticationTest do
  @moduledoc """
  End-to-end tests for authentication flows.
  """

  use SoupAndNutzWeb.E2ECase, async: false

  describe "authentication flows" do
    test "user can register a new account" do
      navigate_to("/register")

      # Fill registration form
      fill_form(%{
        "user_email" => "newuser@example.com",
        "user_password" => "password123",
        "user_password_confirmation" => "password123",
        "user_first_name" => "John",
        "user_last_name" => "Doe",
        "user_date_of_birth" => "1990-01-01"
      })

      submit_form()

      # Should redirect to dashboard
      assert_current_path("/")
      assert_text_present("Welcome")
    end

    test "user can login with valid credentials" do
      user = insert(:user)

      navigate_to("/login")

      fill_form(%{
        "user_email" => user.email,
        "user_password" => "password123"
      })

      submit_form()

      # Should redirect to dashboard
      assert_current_path("/")
      assert_text_present("Welcome")
    end

    test "user cannot login with invalid credentials" do
      user = insert(:user)

      navigate_to("/login")

      fill_form(%{
        "user_email" => user.email,
        "user_password" => "wrongpassword"
      })

      submit_form()

      # Should stay on login page with error
      assert_current_path("/login")
      assert_text_present("Invalid email or password")
    end

    test "user can logout" do
      user = sign_in_user()

      # Should be logged in
      assert_current_path("/")

      sign_out_user()

      # Should redirect to login page
      assert_current_path("/login")
    end

    test "unauthenticated user is redirected to login" do
      navigate_to("/assets")

      # Should redirect to login
      assert_current_path("/login")
    end

    test "user can update profile" do
      user = sign_in_user()

      navigate_to("/profile")

      # Update profile information
      fill_form(%{
        "user_first_name" => "Updated",
        "user_last_name" => "Name"
      })

      submit_form()

      # Should show success message
      assert_text_present("Profile updated successfully")
      assert_text_present("Updated Name")
    end

    test "user can change password" do
      user = sign_in_user()

      navigate_to("/profile")

      # Fill password change form
      fill_form(%{
        "user_current_password" => "password123",
        "user_password" => "newpassword123",
        "user_password_confirmation" => "newpassword123"
      })

      submit_form()

      # Should show success message
      assert_text_present("Password updated successfully")
    end
  end

  describe "navigation and access control" do
    test "authenticated user can access protected routes" do
      user = sign_in_user()

      # Test access to various protected routes
      navigate_to("/assets")
      assert_current_path("/assets")

      navigate_to("/debt_obligations")
      assert_current_path("/debt_obligations")

      navigate_to("/cash_flows")
      assert_current_path("/cash_flows")
    end

    test "sidebar is visible for authenticated users" do
      user = sign_in_user()

      navigate_to("/")

      # Check for sidebar elements
      assert_element_present({:css, ".sidebar"})
      assert_element_present({:css, "a[href='/assets']"})
      assert_element_present({:css, "a[href='/debt_obligations']"})
      assert_element_present({:css, "a[href='/cash_flows']"})
    end

    test "sidebar is not visible for unauthenticated users" do
      navigate_to("/")

      # Sidebar should not be present
      assert_element_not_present({:css, ".sidebar"})
    end
  end
end
