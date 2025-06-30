defmodule SoupAndNutzWeb.Plugs.Authenticate do
  @moduledoc """
  Authentication plug that ensures users are logged in before accessing protected routes.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :user_id) do
      conn
    else
      conn
      |> put_flash(:error, "Please log in to access this page.")
      |> redirect(to: "/auth/login")
      |> halt()
    end
  end
end
