defmodule SoupAndNutzWeb.Plugs.OptionalAuthenticate do
  @moduledoc """
  Optional authentication plug that sets current_user if available but doesn't require authentication.
  """

  import Plug.Conn
  alias SoupAndNutz.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil ->
        assign(conn, :current_user, nil)

      id ->
        case Accounts.get_user(id) do
          nil ->
            # User not found, clear session
            conn
            |> delete_session(:user_id)
            |> assign(:current_user, nil)

          user when user.is_active ->
            assign(conn, :current_user, user)

          _user ->
            # User account is deactivated, remove session but don't redirect
            conn
            |> delete_session(:user_id)
            |> assign(:current_user, nil)
        end
    end
  end
end
