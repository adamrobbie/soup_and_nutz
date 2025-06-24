defmodule SoupAndNutzWeb.DebtObligationLive.Show do
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
     |> assign(:debt_obligation, FinancialInstruments.get_debt_obligation!(id))}
  end

  defp page_title(:show), do: "Show Debt Obligation"
  defp page_title(:edit), do: "Edit Debt Obligation"
end
