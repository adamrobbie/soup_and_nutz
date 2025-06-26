defmodule SoupAndNutzWeb.MetricsController do
  use SoupAndNutzWeb, :controller

  def index(conn, _params) do
    text(conn, "# HELP app_up 1 if the app is up\n# TYPE app_up gauge\napp_up 1\n")
  end
end
