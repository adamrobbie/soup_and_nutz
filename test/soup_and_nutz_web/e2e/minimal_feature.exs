defmodule SoupAndNutzWeb.E2E.MinimalFeature do
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

  feature "can load the home page", %{session: session} do
    session
    |> visit("/")
    |> assert_has(Query.css("span", text: "Soup & Nutz"))
  end

  feature "can access registration page", %{session: session} do
    session
    |> visit("/auth/register")
    |> assert_has(Query.css("h2", text: "Create your account"))
  end

  feature "can access login page", %{session: session} do
    session
    |> visit("/auth/login")
    |> assert_has(Query.css("h2", text: "Sign in to your account"))
  end
end
