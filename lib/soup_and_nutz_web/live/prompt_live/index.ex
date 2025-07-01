defmodule SoupAndNutzWeb.PromptLive.Index do
  use SoupAndNutzWeb, :live_view
  alias SoupAndNutz.AI.FinancialAdvisor
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.AI.ConversationMemory

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       prompt: "",
       result: nil,
       loading: false,
       history: [],
       current_user: get_current_user(session)
     )}
  end

  @impl true
  def handle_event("submit_prompt", %{"prompt" => prompt}, socket) do
    user = socket.assigns.current_user
    {:noreply, assign(socket, loading: true, result: nil, prompt: prompt)}

    # In test mode, process synchronously to avoid timing issues
    if Mix.env() == :test do
      send(self(), {:process_prompt, prompt, user})
      {:noreply, socket}
    else
      Task.start(fn ->
        send(self(), {:process_prompt, prompt, user})
      end)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("example_prompt", %{"prompt" => prompt}, socket) do
    {:noreply, assign(socket, prompt: prompt)}
  end

  @impl true
  def handle_info({:process_prompt, prompt, user}, socket) do
    # Handle case where user is nil (e.g., in tests)
    user_id = if user, do: user.id, else: nil

    # Get the financial advisor from config (allows mocking in tests)
    financial_advisor = Application.get_env(:soup_and_nutz, :financial_advisor, FinancialAdvisor)

    result = if is_map(financial_advisor) do
      financial_advisor.process_user_input.(prompt, user_id)
    else
      financial_advisor.process_user_input(prompt, user_id)
    end

    case result do
      {:ok, %{type: :asset_created, asset: asset}} ->
        {:noreply, update_history(socket, prompt, {:ok, "Asset created: #{asset.asset_name}"}, false)}
      {:ok, %{type: :debt_created, debt: debt}} ->
        {:noreply, update_history(socket, prompt, {:ok, "Debt obligation created: #{debt.debt_name}"}, false)}
      {:ok, %{type: :goal_created, goal: goal}} ->
        {:noreply, update_history(socket, prompt, {:ok, "Goal created: #{goal.goal_name}"}, false)}
      {:ok, %{type: :asset_query_result, assets: assets}} ->
        summary = "Found #{length(assets)} assets"
        {:noreply, update_history(socket, prompt, {:ok, summary}, false)}
      {:ok, %{type: :debt_query_result, debts: debts}} ->
        summary = "Found #{length(debts)} debts"
        {:noreply, update_history(socket, prompt, {:ok, summary}, false)}
      {:ok, %{type: :financial_health_analysis, score: score}} ->
        {:noreply, update_history(socket, prompt, {:ok, "Financial health score: #{score}"}, false)}
      {:ok, %{type: :debt_optimization_analysis, suggestions: suggestions}} ->
        summary = "Debt optimization suggestions: #{Enum.join(suggestions, ", ")}"
        {:noreply, update_history(socket, prompt, {:ok, summary}, false)}
      {:ok, %{type: :general_answer, answer: answer}} ->
        {:noreply, update_history(socket, prompt, {:ok, answer}, false)}
      {:ok, %{type: :clarification_needed, questions: questions}} ->
        question_text = Enum.join(questions, "; ")
        {:noreply, update_history(socket, prompt, {:ok, "Please clarify: #{question_text}"}, false)}
      {:error, error} ->
        {:noreply, update_history(socket, prompt, {:error, error}, false)}
    end
  end

  defp get_current_user(session) do
    # Replace with your actual user fetching logic
    Map.get(session, "current_user")
  end

  defp update_history(socket, prompt, result, loading) do
    history = ([{prompt, result}] ++ (socket.assigns.history || [])) |> Enum.take(5)
    assign(socket, result: result, loading: loading, history: history)
  end


end
