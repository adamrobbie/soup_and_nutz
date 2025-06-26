defmodule SoupAndNutzWeb.HealthController do
  use SoupAndNutzWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
