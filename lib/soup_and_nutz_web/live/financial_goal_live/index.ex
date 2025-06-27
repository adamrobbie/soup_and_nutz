defmodule SoupAndNutzWeb.FinancialGoalLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialGoals
  alias SoupAndNutz.FinancialGoals.FinancialGoal

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :financial_goals, list_financial_goals(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case socket.assigns.live_action do
      :new ->
        {:noreply, push_navigate(socket, to: "/financial_goals")}
      :edit ->
        {:noreply, push_navigate(socket, to: "/financial_goals")}
      _ ->
        {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Financial Goals")
    |> assign(:financial_goal, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Financial Goal")
    |> assign(:financial_goal, %FinancialGoal{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Financial Goal")
    |> assign(:financial_goal, FinancialGoals.get_financial_goal!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    financial_goal = FinancialGoals.get_financial_goal!(id)
    {:ok, _} = FinancialGoals.delete_financial_goal(financial_goal)

    {:noreply, assign(socket, :financial_goals, list_financial_goals(socket.assigns.current_user.id))}
  end

  def handle_event("saved", %{financial_goal: _financial_goal}, socket) do
    {:noreply, assign(socket, :financial_goals, list_financial_goals(socket.assigns.current_user.id))}
  end

  defp list_financial_goals(user_id) do
    FinancialGoals.list_financial_goals_by_user(user_id)
  end
end
