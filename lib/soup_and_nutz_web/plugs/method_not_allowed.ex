defmodule SoupAndNutzWeb.Plugs.MethodNotAllowed do
  @moduledoc """
  A plug that returns a 405 Method Not Allowed response.

  This plug is used to handle HTTP methods that are not supported
  for a particular endpoint, returning a proper HTTP 405 status code.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_status(405)
    |> put_resp_content_type("text/plain")
    |> send_resp(405, "Method Not Allowed")
    |> halt()
  end

  def index(conn, _params) do
    conn
    |> put_status(405)
    |> put_resp_content_type("text/plain")
    |> send_resp(405, "Method Not Allowed")
  end
end
