defmodule SoupAndNutzWeb.Plugs.Authenticate do
  @moduledoc """
  Authentication plug that ensures users are logged in before accessing protected routes.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias SoupAndNutz.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      case Accounts.get_user(user_id) do
        nil ->
          # User not found, clear session and redirect
          conn
          |> delete_session(:user_id)
          |> put_flash(:error, "Please log in to access this page.")
          |> redirect(to: "/auth/login")
          |> halt()

        user when user.is_active ->
          # User found and active, set current_user and continue
          conn
          |> assign(:current_user, user)

        _user ->
          # User account is deactivated, clear session and redirect
          conn
          |> delete_session(:user_id)
          |> put_flash(:error, "Your account has been deactivated.")
          |> redirect(to: "/auth/login")
          |> halt()
      end
    else
      conn
      |> put_flash(:error, "Please log in to access this page.")
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end
end
