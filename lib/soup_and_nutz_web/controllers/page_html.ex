defmodule SoupAndNutzWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use SoupAndNutzWeb, :html
  import SoupAndNutzWeb.FinancialHelpers

  embed_templates "page_html/*"

  def render("welcome.html", assigns) do
    Phoenix.View.render_to_iodata(__MODULE__, "welcome.html", assigns, layout: false)
  end
end
