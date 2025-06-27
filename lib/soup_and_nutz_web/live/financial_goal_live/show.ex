defmodule SoupAndNutzWeb.FinancialGoalLive.Show do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialGoals

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:financial_goal, FinancialGoals.get_financial_goal!(id))}
  end

  defp page_title(:show), do: "Show Financial Goal"
  defp page_title(:edit), do: "Edit Financial Goal"
end
