defmodule SoupAndNutzWeb.Plugs.Authenticate do
  @moduledoc """
  Authentication plug that ensures users are logged in before accessing protected routes.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias SoupAndNutz.Accounts
  alias SoupAndNutzWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil ->
        # User is not authenticated
        conn
        |> put_flash(:error, "Please log in to access this page.")
        |> redirect(to: Routes.auth_path(conn, :login))
        |> halt()

      id ->
        case Accounts.get_user!(id) do
          user when user.is_active ->
            # User is authenticated and active
            assign(conn, :current_user, user)

          _user ->
            # User account is deactivated
            conn
            |> delete_session(:user_id)
            |> put_flash(:error, "Your account has been deactivated. Please contact support.")
            |> redirect(to: Routes.auth_path(conn, :login))
            |> halt()
        end
    end
  end
end
