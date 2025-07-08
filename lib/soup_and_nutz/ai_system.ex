defmodule SoupAndNutz.AISystem do
  @moduledoc """
  Fault-tolerant AI system built with LangChain and Elixir OTP.

  Features:
  - Circuit breaker pattern for AI service failures
  - Dynamic worker pools with load balancing
  - Automatic process restart via supervision trees
  - Conversation persistence
  - Health monitoring
  """

  def chat(message) do
    chat(message, [])
  end

  def chat(message, opts \\ []) do
    conversation_id = Keyword.get(opts, :conversation_id, "default")
    context = Keyword.get(opts, :context, %{})

    case SoupAndNutz.AISystem.MessageRouter.route_message(message, context) do
      {:ok, response} ->
        # Save both user message and AI response
        SoupAndNutz.AISystem.ConversationManager.save_message(conversation_id, "user", message)
        SoupAndNutz.AISystem.ConversationManager.save_message(conversation_id, "assistant", response)
        {:ok, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_conversation_history(conversation_id) do
    SoupAndNutz.AISystem.ConversationManager.get_conversation(conversation_id)
  end

  def system_status do
    SoupAndNutz.AISystem.HealthMonitor.get_system_status()
  end

  def add_worker(worker_id, config \\ %{}) do
    SoupAndNutz.AISystem.AIWorkerSupervisor.start_worker(worker_id, config)
  end

  def remove_worker(worker_id) do
    SoupAndNutz.AISystem.AIWorkerSupervisor.stop_worker(worker_id)
  end
end
