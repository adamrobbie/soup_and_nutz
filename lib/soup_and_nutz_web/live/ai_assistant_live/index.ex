defmodule SoupAndNutzWeb.AIAssistantLive.Index do
  use SoupAndNutzWeb, :live_view
  alias SoupAndNutz.AI.FinancialAdvisor
  alias SoupAndNutz.AI.ConversationMemory

  @impl true
  def mount(_params, session, socket) do
    user = get_current_user(session)
    conversation_id = ConversationMemory.generate_conversation_id()

    {:ok,
     assign(socket,
       user_input: "",
       messages: [],
       loading: false,
       current_user: user,
       conversation_id: conversation_id,
       suggestions: get_initial_suggestions(),
       clarification_context: nil,
       conversation_list: [],
       show_conversation_switcher: false
     )}
  end

  @impl true
  def handle_event("submit_message", %{"user_input" => user_input}, socket) do
    user = socket.assigns.current_user
    conversation_id = socket.assigns.conversation_id
    clarification_context = socket.assigns.clarification_context

    if user && String.trim(user_input) != "" do
      # Add user message to chat
      user_message = %{
        id: generate_message_id(),
        type: :user,
        content: user_input,
        timestamp: DateTime.utc_now()
      }

      socket = assign(socket,
        messages: [user_message | socket.assigns.messages],
        loading: true,
        user_input: ""
      )

      # Process with AI advisor (pass clarification context if in clarification mode)
      Task.start(fn ->
        send(self(), {:ai_response, user_input, user.id, conversation_id, clarification_context})
      end)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("suggestion_click", %{"suggestion" => suggestion}, socket) do
    {:noreply, assign(socket, user_input: suggestion)}
  end

  @impl true
  def handle_event("clarification_response", %{"response" => response}, socket) do
    # Handle clarification response
    user = socket.assigns.current_user
    conversation_id = socket.assigns.conversation_id
    clarification_context = socket.assigns.clarification_context

    user_message = %{
      id: generate_message_id(),
      type: :user,
      content: response,
      timestamp: DateTime.utc_now(),
      is_clarification: true
    }

    socket = assign(socket,
      messages: [user_message | socket.assigns.messages],
      loading: true,
      clarification_context: nil
    )

    # Process clarification response
    Task.start(fn ->
      send(self(), {:ai_response, response, user.id, conversation_id, clarification_context})
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_conversation", %{"conversation_id" => conversation_id}, socket) do
    # Switch to a different conversation
    _user = socket.assigns.current_user

    # Get conversation history
    conversation_history = ConversationMemory.get_conversation_context(conversation_id)

    # Convert to message format
    messages = conversation_history
    |> Enum.map(fn memory ->
      %{
        id: generate_message_id(),
        type: :ai,
        content: memory.response,
        timestamp: memory.inserted_at,
        response_type: memory.action_taken
      }
    end)
    |> Enum.reverse()

    {:noreply, assign(socket,
      conversation_id: conversation_id,
      messages: messages,
      clarification_context: nil,
      show_conversation_switcher: false,
      suggestions: generate_conversation_suggestions(conversation_history)
    )}
  end

  @impl true
  def handle_event("show_conversation_switcher", _params, socket) do
    user = socket.assigns.current_user

    # Get user's conversations
    conversations = get_user_conversations(user.id)

    {:noreply, assign(socket,
      conversation_list: conversations,
      show_conversation_switcher: true
    )}
  end

  @impl true
  def handle_event("hide_conversation_switcher", _params, socket) do
    {:noreply, assign(socket, show_conversation_switcher: false)}
  end

  @impl true
  def handle_event("merge_conversations", %{"conversation_ids" => conversation_ids}, socket) do
    user = socket.assigns.current_user

    # Merge conversations
    case FinancialAdvisor.merge_conversations(user.id, conversation_ids) do
      {:ok, result} ->
        # Show merge result
        merge_message = %{
          id: generate_message_id(),
          type: :ai,
          content: result.message,
          timestamp: DateTime.utc_now(),
          response_type: :conversations_merged
        }

        {:noreply, assign(socket,
          messages: [merge_message | socket.assigns.messages],
          show_conversation_switcher: false
        )}

      {:error, error} ->
        error_message = %{
          id: generate_message_id(),
          type: :ai,
          content: "Failed to merge conversations: #{error}",
          timestamp: DateTime.utc_now(),
          error: true
        }

        {:noreply, assign(socket,
          messages: [error_message | socket.assigns.messages],
          show_conversation_switcher: false
        )}
    end
  end

  @impl true
  def handle_event("clear_chat", _params, socket) do
    new_conversation_id = ConversationMemory.generate_conversation_id()
    {:noreply, assign(socket,
      messages: [],
      conversation_id: new_conversation_id,
      clarification_context: nil,
      suggestions: get_initial_suggestions(),
      show_conversation_switcher: false
    )}
  end

  @impl true
  def handle_info({:ai_response, user_input, user_id, conversation_id, clarification_context}, socket) do
    case FinancialAdvisor.process_user_input(user_input, user_id, conversation_id, clarification_context) do
      {:ok, response} ->
        ai_message = format_ai_response(response)

        # Handle clarification state
        clarification_context = case response do
          %{type: :clarification_needed, clarification_context: context} -> context
          _ -> nil
        end

        socket = assign(socket,
          messages: [ai_message | socket.assigns.messages],
          loading: false,
          clarification_context: clarification_context,
          suggestions: generate_contextual_suggestions(response, socket.assigns.messages)
        )

        {:noreply, socket}

      {:error, error} ->
        error_message = %{
          id: generate_message_id(),
          type: :ai,
          content: "I'm sorry, I encountered an error: #{format_error(error)}",
          timestamp: DateTime.utc_now(),
          error: true
        }

        socket = assign(socket,
          messages: [error_message | socket.assigns.messages],
          loading: false,
          clarification_context: nil
        )

        {:noreply, socket}
    end
  end

  # Private helper functions

  defp get_current_user(session) do
    Map.get(session, "current_user")
  end

  defp get_user_conversations(user_id) do
    # Get user's recent conversations
    ConversationMemory.get_recent_context(user_id, 10)
    |> Enum.group_by(& &1.conversation_id)
    |> Enum.map(fn {conversation_id, memories} ->
      %{
        conversation_id: conversation_id,
        summary: summarize_conversation(memories),
        message_count: length(memories),
        last_activity: get_last_activity(memories)
      }
    end)
    |> Enum.sort_by(& &1.last_activity, :desc)
  end

  defp summarize_conversation(memories) do
    # Extract topics from conversation
    topics = memories
    |> Enum.map(fn memory -> memory.message end)
    |> Enum.join(" ")
    |> extract_topics()

    case topics do
      [] -> "General conversation"
      topics -> "Topics: #{Enum.join(topics, ", ")}"
    end
  end

  defp extract_topics(text) do
    # Simple topic extraction - in a real app, you'd use AI
    cond do
      String.contains?(text, "asset") -> ["assets"]
      String.contains?(text, "debt") -> ["debts"]
      String.contains?(text, "investment") -> ["investments"]
      String.contains?(text, "goal") -> ["goals"]
      true -> []
    end
  end

  defp get_last_activity(memories) do
    memories
    |> Enum.max_by(& &1.inserted_at, fn -> DateTime.utc_now() end)
    |> Map.get(:inserted_at)
  end

  defp format_ai_response(response) do
    content = case response do
      %{type: :asset_created, asset: asset, message: message, suggestions: suggestions} ->
        """
        ✅ #{message}

        **Asset Details:**
        - Name: #{asset.asset_name}
        - Type: #{asset.asset_type}
        - Value: #{format_currency(asset.fair_value)}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :debt_created, debt: debt, message: message, suggestions: suggestions} ->
        """
        ✅ #{message}

        **Debt Details:**
        - Name: #{debt.debt_name}
        - Type: #{debt.debt_type}
        - Balance: #{format_currency(debt.outstanding_balance)}
        - Interest Rate: #{format_percentage(debt.interest_rate)}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :asset_query_result, assets: assets, summary: summary, suggestions: suggestions} ->
        """
        📊 #{summary}

        **Assets Found:**
        #{Enum.map_join(assets, "\n", fn asset -> "- #{asset.asset_name}: #{format_currency(asset.fair_value)}" end)}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :debt_query_result, debts: debts, summary: summary, suggestions: suggestions} ->
        """
        📊 #{summary}

        **Debts Found:**
        #{Enum.map_join(debts, "\n", fn debt -> "- #{debt.debt_name}: #{format_currency(debt.outstanding_balance)}" end)}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :financial_health_analysis, score: score, summary: summary, recommendations: recommendations} ->
        """
        🏥 **Financial Health Score: #{score}/100**

        **Summary:**
        - Total Assets: #{format_currency(summary.total_assets)}
        - Total Debts: #{format_currency(summary.total_debts)}
        - Net Worth: #{format_currency(summary.net_worth)}

        **Recommendations:**
        #{Enum.map_join(recommendations, "\n", &"- #{&1}")}
        """

      %{type: :net_worth_calculation, net_worth: net_worth, breakdown: breakdown} ->
        """
        💰 **Net Worth: #{format_currency(net_worth)}**

        **Breakdown:**
        - Assets: #{format_currency(breakdown.assets)}
        - Debts: #{format_currency(breakdown.debts)}
        """

      %{type: :debt_optimization_analysis, debts: debts, suggestions: suggestions} ->
        """
        🔧 **Debt Optimization Analysis**

        **Your Debts:**
        #{Enum.map_join(debts, "\n", fn debt -> "- #{debt.debt_name}: #{format_currency(debt.outstanding_balance)} (#{format_percentage(debt.interest_rate)} APR)" end)}

        **Optimization Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :investment_allocation_analysis, investment_assets: assets, suggestions: suggestions} ->
        """
        📈 **Investment Allocation Analysis**

        **Your Investments:**
        #{Enum.map_join(assets, "\n", fn asset -> "- #{asset.asset_name}: #{format_currency(asset.fair_value)}" end)}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :clarification_needed, questions: questions, suggestions: suggestions} ->
        """
        🤔 I need some clarification to help you better:

        #{Enum.map_join(questions, "\n", &"- #{&1}")}

        **Quick responses:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :conversation_switched, message: message, suggestions: suggestions} ->
        """
        🔄 #{message}

        **Suggestions:**
        #{Enum.map_join(suggestions, "\n", &"- #{&1}")}
        """

      %{type: :conversations_merged, message: message} ->
        """
        🔗 #{message}
        """

      %{type: :general_answer, answer: answer} ->
        answer

      _ ->
        "I processed your request. Here's what I found: #{inspect(response)}"
    end

    %{
      id: generate_message_id(),
      type: :ai,
      content: content,
      timestamp: DateTime.utc_now(),
      response_type: Map.get(response, :type)
    }
  end

  defp get_initial_suggestions do
    [
      "Add a new asset",
      "Add a new debt",
      "What's my net worth?",
      "Analyze my financial health",
      "Show me my assets",
      "Show me my debts",
      "Optimize my debt",
      "Analyze my investments",
      "Switch conversation",
      "Merge conversations"
    ]
  end

  defp generate_contextual_suggestions(response, _messages) do
    case response do
      %{type: :asset_created} ->
        [
          "Add another asset",
          "Show me all my assets",
          "What's my net worth?",
          "Analyze my investments"
        ]

      %{type: :debt_created} ->
        [
          "Add another debt",
          "Show me all my debts",
          "Optimize my debt",
          "What's my debt-to-income ratio?"
        ]

      %{type: :financial_health_analysis} ->
        [
          "How can I improve my score?",
          "Show me my net worth",
          "Analyze my spending",
          "Get investment recommendations"
        ]

      %{type: :debt_optimization_analysis} ->
        [
          "Show me my highest interest debts",
          "Calculate debt payoff timeline",
          "Find debt consolidation options",
          "What's my credit utilization?"
        ]

      %{type: :clarification_needed, suggestions: suggestions} ->
        suggestions

      _ ->
        get_initial_suggestions()
    end
  end

  defp generate_conversation_suggestions(conversation_history) do
    case conversation_history do
      [] -> ["Start a new conversation", "Ask about your finances"]
      _history ->
        ["Continue this conversation", "Ask a follow-up question", "Start a new topic"]
    end
  end

  defp format_currency(value) when is_nil(value), do: "$0.00"
  defp format_currency(value) do
    case Decimal.to_string(value) do
      "NaN" -> "$0.00"
      str -> "$#{str}"
    end
  end

  defp format_percentage(value) when is_nil(value), do: "0%"
  defp format_percentage(value) do
    case Decimal.to_string(value) do
      "NaN" -> "0%"
      str -> "#{str}%"
    end
  end

  defp format_error(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end
  defp format_error(err) when is_binary(err), do: err
  defp format_error(err), do: inspect(err)

  defp generate_message_id do
    "msg_#{System.system_time(:millisecond)}_#{:rand.uniform(1000)}"
  end
end
