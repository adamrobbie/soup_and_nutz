defmodule SoupAndNutz.AISystem.EmbeddingService do
  @moduledoc """
  Service for generating and managing text embeddings.
  """

  alias SoupAndNutz.AISystem.VectorDB
  require Logger

  @doc """
  Generates an embedding for the given text using OpenAI's embedding model.
  """
    def generate_embedding(text) when is_binary(text) do
    call_openai_embedding_api(text)
  end

  @doc """
  Stores an embedding with metadata in the vector database.
  """
  def store_embedding(content, embedding, metadata \\ %{}) do
    attrs = %{
      content: content,
      embedding: embedding,
      metadata: metadata
    }

    case VectorDB.store_embedding(attrs) do
      {:ok, stored_embedding} ->
        Logger.debug("Stored embedding for content: #{String.slice(content, 0, 50)}...")
        {:ok, stored_embedding}

      {:error, reason} ->
        Logger.error("Failed to store embedding: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Stores an embedding with user and conversation context.
  """
  def store_embedding_with_context(content, embedding, user_id, conversation_id, message_id, metadata \\ %{}) do
    attrs = %{
      content: content,
      embedding: embedding,
      user_id: user_id,
      conversation_id: conversation_id,
      message_id: message_id,
      metadata: metadata
    }

    case VectorDB.store_embedding(attrs) do
      {:ok, stored_embedding} ->
        Logger.debug("Stored embedding with context for user #{user_id}")
        {:ok, stored_embedding}

      {:error, reason} ->
        Logger.error("Failed to store embedding with context: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Finds similar content using vector similarity search.
  """
  def find_similar_content(query_embedding, limit \\ 10, threshold \\ 0.7) do
    case VectorDB.find_similar_embeddings(query_embedding, limit, threshold) do
      {:ok, embeddings} ->
        {:ok, embeddings}

      {:error, reason} ->
        Logger.error("Failed to find similar content: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Finds similar content for a specific user.
  """
  def find_similar_content_for_user(query_embedding, user_id, limit \\ 10, threshold \\ 0.7) do
    case VectorDB.find_similar_embeddings_for_user(query_embedding, user_id, limit, threshold) do
      {:ok, embeddings} ->
        {:ok, embeddings}

      {:error, reason} ->
        Logger.error("Failed to find similar content for user: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Finds similar content for a specific conversation.
  """
  def find_similar_content_for_conversation(query_embedding, conversation_id, limit \\ 10, threshold \\ 0.7) do
    case VectorDB.find_similar_embeddings_for_conversation(query_embedding, conversation_id, limit, threshold) do
      {:ok, embeddings} ->
        {:ok, embeddings}

      {:error, reason} ->
        Logger.error("Failed to find similar content for conversation: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Processes and stores embeddings for a conversation message.
  """
  def process_message_embedding(message_content, user_id, conversation_id, message_id) do
    case generate_embedding(message_content) do
      {:ok, embedding} ->
        metadata = %{
          "type" => "message",
          "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "content_length" => String.length(message_content)
        }

        store_embedding_with_context(message_content, embedding, user_id, conversation_id, message_id, metadata)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets conversation context by finding similar previous messages.
  """
  def get_conversation_context(current_message, conversation_id, limit \\ 5) do
    case generate_embedding(current_message) do
      {:ok, embedding} ->
        case find_similar_content_for_conversation(embedding, conversation_id, limit, 0.6) do
          {:ok, similar_embeddings} ->
            context = Enum.map(similar_embeddings, fn embedding ->
              %{
                content: embedding["content"],
                similarity: embedding["similarity"],
                metadata: embedding["metadata"]
              }
            end)
            {:ok, context}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private function to call OpenAI's embedding API
  defp call_openai_embedding_api(text) do
    # For now, we'll use a mock embedding
    # In production, you'd call the actual OpenAI API
    mock_embedding = generate_mock_embedding(text)
    {:ok, mock_embedding}
  end

    # Generate a mock embedding for testing
  defp generate_mock_embedding(text) do
    # Create a deterministic "embedding" based on the text
    # In production, replace this with actual OpenAI API call
    hash = :crypto.hash(:sha256, text)
    |> Base.encode16()
    |> String.slice(0, 64)  # Use more characters for better distribution

    # Convert to a list of floats (1536 dimensions like OpenAI embeddings)
    hash
    |> String.graphemes()
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] ->
      String.to_integer(a <> b, 16) / 255.0
    end)
    |> List.duplicate(48)  # 1536 / 32 = 48 (since we get 32 floats from 64 chars)
    |> List.flatten()
    |> Enum.slice(0, 1536)
  end
end
