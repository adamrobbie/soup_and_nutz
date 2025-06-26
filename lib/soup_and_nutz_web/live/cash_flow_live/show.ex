defmodule SoupAndNutzWeb.CashFlowLive.Show do
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
     |> assign(:cash_flow, FinancialInstruments.get_cash_flow!(id))}
  end

  defp page_title(:show), do: "Show Cash flow"
  defp page_title(:edit), do: "Edit Cash flow"
end
