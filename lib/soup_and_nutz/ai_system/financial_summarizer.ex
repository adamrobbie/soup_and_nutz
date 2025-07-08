defmodule SoupAndNutz.AISystem.FinancialSummarizer do
  @moduledoc """
  Summarizes financial conversations and extracts key insights using LangChain's SummarizeConversationChain.

  This module can create concise summaries of financial discussions, extract action items,
  and identify key financial insights from conversations.
  """

    alias LangChain.Chains.SummarizeConversationChain
  alias LangChain.Message
  alias SoupAndNutz.AISystem.ModelProvider

  @doc """
  Summarizes a financial conversation.
  """
  def summarize_conversation(messages) do
    # Convert messages to text format
    conversation_text = Enum.map_join(messages, "\n\n", fn message ->
      case message.role do
        :user -> "User: #{message.content}"
        :assistant -> "Assistant: #{message.content}"
        _ -> "#{message.role}: #{message.content}"
      end
    end)

    case ModelProvider.get_model() do
      {:ok, llm} ->
        chain = SummarizeConversationChain.new!(%{
          llm: llm,
          keep_count: 2,
          threshold_count: 2
        })

        case SummarizeConversationChain.run(chain, conversation_text) do
          {:ok, result} ->
            # Extract the summary from the result
            case result.last_message do
              %{content: content} when is_binary(content) ->
                {:ok, content}
              _ ->
                {:ok, "Conversation summarized"}
            end
          {:error, _chain, reason} ->
            {:error, "Failed to summarize conversation: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

    @doc """
  Extracts action items from a financial conversation.
  """
  def extract_action_items(messages) do
    # Convert messages to text format
    conversation_text = Enum.map_join(messages, "\n\n", fn message ->
      case message.role do
        :user -> "User: #{message.content}"
        :assistant -> "Assistant: #{message.content}"
        _ -> "#{message.role}: #{message.content}"
      end
    end)

    case ModelProvider.get_model() do
      {:ok, llm} ->
        chain = SummarizeConversationChain.new!(%{
          llm: llm,
          keep_count: 2,
          threshold_count: 2
        })

        case SummarizeConversationChain.run(chain, conversation_text) do
          {:ok, result} ->
            case result.last_message do
              %{content: content} when is_binary(content) ->
                {:ok, content}
              _ ->
                {:ok, "Action items extracted"}
            end
          {:error, _chain, reason} ->
            {:error, "Failed to extract action items: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

    @doc """
  Extracts key financial insights from a conversation.
  """
  def extract_financial_insights(messages) do
    # Convert messages to text format
    conversation_text = Enum.map_join(messages, "\n\n", fn message ->
      case message.role do
        :user -> "User: #{message.content}"
        :assistant -> "Assistant: #{message.content}"
        _ -> "#{message.role}: #{message.content}"
      end
    end)

    case ModelProvider.get_model() do
      {:ok, llm} ->
        chain = SummarizeConversationChain.new!(%{
          llm: llm,
          keep_count: 2,
          threshold_count: 2
        })

        case SummarizeConversationChain.run(chain, conversation_text) do
          {:ok, result} ->
            case result.last_message do
              %{content: content} when is_binary(content) ->
                {:ok, content}
              _ ->
                {:ok, "Financial insights extracted"}
            end
          {:error, _chain, reason} ->
            {:error, "Failed to extract insights: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

    @doc """
  Creates a financial health summary from a conversation.
  """
  def create_financial_health_summary(messages) do
    # Convert messages to text format
    conversation_text = Enum.map_join(messages, "\n\n", fn message ->
      case message.role do
        :user -> "User: #{message.content}"
        :assistant -> "Assistant: #{message.content}"
        _ -> "#{message.role}: #{message.content}"
      end
    end)

    case ModelProvider.get_model() do
      {:ok, llm} ->
        chain = SummarizeConversationChain.new!(%{
          llm: llm,
          keep_count: 2,
          threshold_count: 2
        })

        case SummarizeConversationChain.run(chain, conversation_text) do
          {:ok, result} ->
            case result.last_message do
              %{content: content} when is_binary(content) ->
                {:ok, content}
              _ ->
                {:ok, "Financial health summary created"}
            end
          {:error, _chain, reason} ->
            {:error, "Failed to create health summary: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

    @doc """
  Summarizes a conversation for follow-up purposes.
  """
  def create_follow_up_summary(messages) do
    # Convert messages to text format
    conversation_text = Enum.map_join(messages, "\n\n", fn message ->
      case message.role do
        :user -> "User: #{message.content}"
        :assistant -> "Assistant: #{message.content}"
        _ -> "#{message.role}: #{message.content}"
      end
    end)

    case ModelProvider.get_model() do
      {:ok, llm} ->
        chain = SummarizeConversationChain.new!(%{
          llm: llm,
          keep_count: 2,
          threshold_count: 2
        })

        case SummarizeConversationChain.run(chain, conversation_text) do
          {:ok, result} ->
            case result.last_message do
              %{content: content} when is_binary(content) ->
                {:ok, content}
              _ ->
                {:ok, "Follow-up summary created"}
            end
          {:error, _chain, reason} ->
            {:error, "Failed to create follow-up summary: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end
end
