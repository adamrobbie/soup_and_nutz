defmodule SoupAndNutzWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use SoupAndNutzWeb, :controller` and
  `use SoupAndNutzWeb, :live_view`.
  """
  use SoupAndNutzWeb, :html

  embed_templates "layouts/*"

  @doc """
  Determines the CSS classes for navigation links based on the current path.
  """
  def nav_link_class(assigns, path) do
    current_path = get_current_path(assigns)

    base_classes = "flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-colors"

    if path_matches?(current_path, path) do
      "#{base_classes} bg-gray-800 text-white"
    else
      "#{base_classes} text-gray-400 hover:text-white hover:bg-gray-800"
    end
  end

  defp get_current_path(assigns) do
    cond do
      Map.has_key?(assigns, :socket) && assigns.socket ->
        # LiveView context - extract path from the socket
        case assigns.socket do
          %{view: view_module} ->
            view_module_to_path(view_module)
          _ ->
            "/"
        end
      Map.has_key?(assigns, :conn) && assigns.conn ->
        # Controller context
        assigns.conn.request_path
      true ->
        "/"
    end
  end

  defp view_module_to_path(view_module) do
    case view_module do
      SoupAndNutzWeb.AssetLive.Index -> "/assets"
      SoupAndNutzWeb.AssetLive.Show -> "/assets"
      SoupAndNutzWeb.DebtObligationLive.Index -> "/debt_obligations"
      SoupAndNutzWeb.DebtObligationLive.Show -> "/debt_obligations"
      SoupAndNutzWeb.CashFlowLive.Index -> "/cash_flows"
      SoupAndNutzWeb.CashFlowLive.Show -> "/cash_flows"
      _ -> "/"
    end
  end

  defp path_matches?(current_path, target_path) do
    case target_path do
      "/" -> current_path == "/"
      _ -> String.starts_with?(current_path, target_path)
    end
  end
end
