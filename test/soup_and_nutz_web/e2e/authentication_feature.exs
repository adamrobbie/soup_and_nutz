defmodule SoupAndNutzWeb.E2E.AuthenticationFeature do
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

  feature "user can register and login", %{session: session} do
    # Generate unique test data
    username = "testuser_#{System.system_time()}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/")
    |> assert_has(Query.css("span", text: "Soup & Nutz"))
    |> click(Query.link("Get Started"))
    |> assert_has(Query.css("h2", text: "Create your account"))
    |> fill_in(Query.text_field("First name"), with: "Test")
    |> fill_in(Query.text_field("Last name"), with: "User")
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Username"), with: username)
    |> fill_in(Query.text_field("Password"), with: password)
    |> fill_in(Query.text_field("Confirm password"), with: password)
    |> click(Query.button("Create account"))
    |> assert_has(Query.text("Account created successfully"))
    |> click(Query.link("sign in to your existing account"))
    |> assert_has(Query.css("h2", text: "Sign in to your account"))
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> assert_has(Query.text("Test"))
  end

  feature "user can logout", %{session: session} do
    # First login (assuming user exists from previous test)
    username = "testuser_#{System.system_time() - 1}"
    email = "#{username}@example.com"
    password = "password123"

    session
    |> visit("/auth/login")
    |> assert_has(Query.css("h2", text: "Sign in to your account"))
    |> fill_in(Query.text_field("Email address"), with: email)
    |> fill_in(Query.text_field("Password"), with: password)
    |> click(Query.button("Sign in"))
    |> assert_has(Query.css("h1", text: "Financial Dashboard"))
    |> click(Query.css("button[aria-label*='User']"))
    |> assert_has(Query.link("Sign Out"))
    |> click(Query.link("Sign Out"))
    |> assert_has(Query.text("Soup & Nutz"))
    |> assert_has(Query.link("Sign In"))
  end
end
