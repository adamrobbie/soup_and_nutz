defmodule SoupAndNutzWeb.RouterTest do
  use SoupAndNutzWeb.ConnCase
  alias SoupAndNutz.Factory

  setup do
    user = Factory.insert(:user)
    {:ok, user: user}
  end

  defp authenticate_user(conn, user) do
    conn
    |> fetch_session([])
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
  end

  test "GET /", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/")
    assert html_response(conn, 200) =~ "Financial Dashboard"
  end

  test "GET /assets", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/assets")
    assert html_response(conn, 200) =~ "Assets"
  end

  test "GET /assets/new", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/assets/new")
    assert redirected_to(conn) == ~p"/assets"
  end

  test "GET /assets/:id", %{conn: conn, user: user} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/assets/#{asset}")
    assert html_response(conn, 200) =~ "Show Asset"
  end

  test "GET /assets/:id/edit", %{conn: conn, user: user} do
    asset = SoupAndNutz.FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/assets/#{asset}/edit")
    assert redirected_to(conn) == ~p"/assets"
  end

  test "GET /debt_obligations", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/debt_obligations")
    assert html_response(conn, 200) =~ "Debt Obligations"
  end

  test "GET /debt_obligations/new", %{conn: conn, user: user} do
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/debt_obligations/new")
    assert redirected_to(conn) == ~p"/debt_obligations"
  end

  test "GET /debt_obligations/:id", %{conn: conn, user: user} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/debt_obligations/#{debt}")
    assert html_response(conn, 200) =~ "Show Debt Obligation"
  end

  test "GET /debt_obligations/:id/edit", %{conn: conn, user: user} do
    debt = SoupAndNutz.FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
    conn = conn
    |> authenticate_user(user)
    |> get(~p"/debt_obligations/#{debt}/edit")
    assert redirected_to(conn) == ~p"/debt_obligations"
  end

  test "GET /health", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert json_response(conn, 200)["status"] == "ok"
  end

  test "GET /metrics", %{conn: conn} do
    conn = get(conn, ~p"/metrics")
    assert response(conn, 200) =~ "# HELP"
  end

  test "404 for unknown routes", %{conn: conn} do
    conn = get(conn, "/unknown-route")
    assert response(conn, 405) =~ "Method Not Allowed"
  end

  test "405 for unsupported methods", %{conn: conn} do
    conn = put(conn, ~p"/")
    assert response(conn, 405)
  end
end
