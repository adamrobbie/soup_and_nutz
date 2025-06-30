defmodule SoupAndNutzWeb.FinancialHealthLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialHealthScore

  @impl true
  def mount(_params, _session, socket) do
    current_user = Map.get(socket.assigns, :current_user)

    if current_user do
      health_score = FinancialHealthScore.calculate_health_score(current_user.id)

      {:ok,
       socket
       |> assign(:health_score, health_score)
       |> assign(:page_title, "Financial Health Score")}
    else
      {:ok,
       socket
       |> assign(:health_score, nil)
       |> assign(:page_title, "Financial Health Score")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Financial Health Score")
  end

  defp get_score_color(score) do
    cond do
      score >= 80 -> "text-green-600"
      score >= 60 -> "text-yellow-600"
      score >= 40 -> "text-orange-600"
      true -> "text-red-600"
    end
  end

  defp get_score_bg_color(score) do
    cond do
      score >= 80 -> "bg-green-100"
      score >= 60 -> "bg-yellow-100"
      score >= 40 -> "bg-orange-100"
      true -> "bg-red-100"
    end
  end

  defp get_score_label(score) do
    cond do
      score >= 80 -> "Excellent"
      score >= 60 -> "Good"
      score >= 40 -> "Fair"
      score >= 20 -> "Poor"
      true -> "Very Poor"
    end
  end
end
