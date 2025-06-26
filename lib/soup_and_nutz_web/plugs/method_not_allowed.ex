defmodule SoupAndNutzWeb.Plugs.MethodNotAllowed do
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
