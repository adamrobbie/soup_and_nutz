defmodule SoupAndNutz.AI.ConversationMemory do
  @moduledoc """
  Conversation memory system for maintaining context and history across AI interactions.
  Supports different memory strategies including sliding window, summarization, and vector-based retrieval.
  """

  defstruct [
    :strategy,
    :max_history_length,
    :conversations,
    :summaries,
    :embeddings_cache
  ]

  require Logger

  @default_max_length 50
  @summary_trigger_length 20

  @doc """
  Create a new conversation memory instance.
  """
  def new(options \\ []) do
    strategy = Keyword.get(options, :strategy, :sliding_window)
    max_length = Keyword.get(options, :max_history_length, @default_max_length)
    
    %__MODULE__{
      strategy: strategy,
      max_history_length: max_length,
      conversations: %{},
      summaries: %{},
      embeddings_cache: %{}
    }
  end

  @doc """
  Add a conversation exchange (user message + AI response) to memory.
  """
  def add_exchange(memory, user_id, user_message, ai_response) do
    exchange = %{
      user_message: user_message,
      assistant_response: extract_response_text(ai_response),
      timestamp: DateTime.utc_now(),
      metadata: extract_response_metadata(ai_response)
    }
    
    updated_conversations = add_exchange_to_user_history(memory, user_id, exchange)
    updated_memory = %{memory | conversations: updated_conversations}
    
    # Apply memory management strategy
    apply_memory_strategy(updated_memory, user_id)
  end

  @doc """
  Get recent conversation history for a user.
  """
  def get_recent_history(memory, user_id, limit \\ 10) do
    memory.conversations
    |> Map.get(user_id, [])
    |> Enum.take(limit)
    |> Enum.reverse()  # Return in chronological order
  end

  @doc """
  Get conversation summary for a user.
  """
  def get_conversation_summary(memory, user_id) do
    Map.get(memory.summaries, user_id, "No previous conversation summary.")
  end

  @doc """
  Search conversation history using semantic similarity.
  """
  def search_history(memory, user_id, query, limit \\ 5) do
    user_history = Map.get(memory.conversations, user_id, [])
    
    if Enum.empty?(user_history) do
      []
    else
      # For now, return simple text-based search
      # In a full implementation, you'd use embeddings for semantic search
      text_search_results = simple_text_search(user_history, query, limit)
      text_search_results
    end
  end

  @doc """
  Clear conversation history for a user.
  """
  def clear_user_history(memory, user_id) do
    updated_conversations = Map.delete(memory.conversations, user_id)
    updated_summaries = Map.delete(memory.summaries, user_id)
    updated_embeddings = Map.delete(memory.embeddings_cache, user_id)
    
    %{memory | 
      conversations: updated_conversations,
      summaries: updated_summaries,
      embeddings_cache: updated_embeddings
    }
  end

  @doc """
  Get memory statistics for monitoring and optimization.
  """
  def get_memory_stats(memory) do
    total_conversations = 
      memory.conversations
      |> Map.values()
      |> Enum.map(&length/1)
      |> Enum.sum()
    
    %{
      total_users: map_size(memory.conversations),
      total_exchanges: total_conversations,
      users_with_summaries: map_size(memory.summaries),
      memory_strategy: memory.strategy,
      max_history_length: memory.max_history_length,
      cache_entries: map_size(memory.embeddings_cache)
    }
  end

  @doc """
  Export conversation history for a user.
  """
  def export_user_conversations(memory, user_id) do
    history = Map.get(memory.conversations, user_id, [])
    summary = Map.get(memory.summaries, user_id)
    
    %{
      user_id: user_id,
      conversation_count: length(history),
      conversations: Enum.reverse(history),
      summary: summary,
      exported_at: DateTime.utc_now()
    }
  end

  @doc """
  Import conversation history for a user.
  """
  def import_user_conversations(memory, exported_data) do
    user_id = exported_data.user_id
    conversations = exported_data.conversations || []
    summary = exported_data.summary
    
    updated_conversations = Map.put(memory.conversations, user_id, Enum.reverse(conversations))
    updated_summaries = if summary, do: Map.put(memory.summaries, user_id, summary), else: memory.summaries
    
    %{memory | 
      conversations: updated_conversations,
      summaries: updated_summaries
    }
  end

  # Private Functions

  defp extract_response_text(ai_response) when is_binary(ai_response), do: ai_response
  defp extract_response_text(%{text: text}), do: text
  defp extract_response_text(%{answer: answer}), do: answer
  defp extract_response_text(response) when is_map(response) do
    response[:text] || response["text"] || response[:content] || response["content"] || "No response text"
  end
  defp extract_response_text(_), do: "Invalid response format"

  defp extract_response_metadata(ai_response) when is_map(ai_response) do
    %{
      model: ai_response[:model] || ai_response["model"],
      provider: ai_response[:provider] || ai_response["provider"],
      usage: ai_response[:usage] || ai_response["usage"],
      processing_time: ai_response[:metadata][:total_duration] || 0
    }
  end
  defp extract_response_metadata(_), do: %{}

  defp add_exchange_to_user_history(memory, user_id, exchange) do
    current_history = Map.get(memory.conversations, user_id, [])
    updated_history = [exchange | current_history]
    
    Map.put(memory.conversations, user_id, updated_history)
  end

  defp apply_memory_strategy(memory, user_id) do
    case memory.strategy do
      :sliding_window -> apply_sliding_window_strategy(memory, user_id)
      :summarization -> apply_summarization_strategy(memory, user_id)
      :vector_store -> apply_vector_store_strategy(memory, user_id)
      _ -> memory  # No strategy applied
    end
  end

  defp apply_sliding_window_strategy(memory, user_id) do
    current_history = Map.get(memory.conversations, user_id, [])
    
    if length(current_history) > memory.max_history_length do
      trimmed_history = Enum.take(current_history, memory.max_history_length)
      updated_conversations = Map.put(memory.conversations, user_id, trimmed_history)
      
      Logger.debug("Trimmed conversation history for user #{user_id} to #{memory.max_history_length} exchanges")
      %{memory | conversations: updated_conversations}
    else
      memory
    end
  end

  defp apply_summarization_strategy(memory, user_id) do
    current_history = Map.get(memory.conversations, user_id, [])
    
    if length(current_history) > @summary_trigger_length do
      # In a real implementation, you'd use an AI model to generate summaries
      summary = generate_conversation_summary(current_history)
      
      # Keep only recent exchanges and store the summary
      recent_history = Enum.take(current_history, div(@summary_trigger_length, 2))
      
      updated_conversations = Map.put(memory.conversations, user_id, recent_history)
      updated_summaries = Map.put(memory.summaries, user_id, summary)
      
      Logger.info("Generated conversation summary for user #{user_id}")
      %{memory | 
        conversations: updated_conversations,
        summaries: updated_summaries
      }
    else
      memory
    end
  end

  defp apply_vector_store_strategy(memory, user_id) do
    current_history = Map.get(memory.conversations, user_id, [])
    
    if length(current_history) > memory.max_history_length do
      # In a real implementation, you'd store older conversations in a vector database
      # and keep only recent ones in active memory
      
      {recent_history, older_history} = Enum.split(current_history, memory.max_history_length)
      
      # Store older conversations in vector cache (simplified)
      cache_key = "#{user_id}_archived_#{DateTime.utc_now() |> DateTime.to_unix()}"
      updated_cache = Map.put(memory.embeddings_cache, cache_key, older_history)
      
      updated_conversations = Map.put(memory.conversations, user_id, recent_history)
      
      Logger.debug("Archived #{length(older_history)} older exchanges for user #{user_id}")
      %{memory | 
        conversations: updated_conversations,
        embeddings_cache: updated_cache
      }
    else
      memory
    end
  end

  defp generate_conversation_summary(history) do
    # Simplified summary generation - in production, use an AI model
    exchange_count = length(history)
    topics = extract_conversation_topics(history)
    recent_timestamp = List.first(history).timestamp
    
    """
    Conversation Summary (#{exchange_count} exchanges as of #{DateTime.to_date(recent_timestamp)}):
    
    Main topics discussed: #{Enum.join(topics, ", ")}
    
    The user has been actively engaging with the financial advisor AI, 
    discussing various aspects of their financial situation and seeking advice.
    """
  end

  defp extract_conversation_topics(history) do
    # Simple keyword extraction from recent messages
    all_text = 
      history
      |> Enum.take(10)  # Look at recent exchanges
      |> Enum.map(fn exchange -> 
        "#{exchange.user_message} #{exchange.assistant_response}"
      end)
      |> Enum.join(" ")
      |> String.downcase()
    
    financial_keywords = [
      "budget", "savings", "investment", "debt", "retirement", 
      "income", "expenses", "portfolio", "loans", "credit"
    ]
    
    financial_keywords
    |> Enum.filter(fn keyword -> String.contains?(all_text, keyword) end)
    |> Enum.take(5)
    |> case do
      [] -> ["financial planning"]
      topics -> topics
    end
  end

  defp simple_text_search(history, query, limit) do
    query_words = 
      query
      |> String.downcase()
      |> String.split()
      |> MapSet.new()
    
    history
    |> Enum.map(fn exchange ->
      text = "#{exchange.user_message} #{exchange.assistant_response}"
      text_words = 
        text
        |> String.downcase()
        |> String.split()
        |> MapSet.new()
      
      # Calculate simple word overlap score
      overlap = MapSet.intersection(query_words, text_words) |> MapSet.size()
      score = if MapSet.size(query_words) > 0, do: overlap / MapSet.size(query_words), else: 0
      
      {exchange, score}
    end)
    |> Enum.filter(fn {_exchange, score} -> score > 0 end)
    |> Enum.sort_by(fn {_exchange, score} -> score end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {exchange, _score} -> exchange end)
  end
end