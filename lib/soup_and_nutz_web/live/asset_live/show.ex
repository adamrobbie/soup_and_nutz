defmodule SoupAndNutzWeb.AssetLive.Show do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, FinancialInstruments.get_asset!(id))}
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}
end
