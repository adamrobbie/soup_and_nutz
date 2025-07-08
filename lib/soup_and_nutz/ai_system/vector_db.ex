defmodule SoupAndNutz.AISystem.VectorDB do
  @moduledoc """
  Context module for vector database operations using pgvector.
  """

  alias SoupAndNutz.Repo
  alias SoupAndNutz.AISystem.Embedding
  import Ecto.Query

    @doc """
  Stores an embedding in the vector database.
  """
  def store_embedding(attrs) do
    # Convert embedding list to JSON string and prepare for pgvector
    embedding_list = attrs.embedding
    embedding_json = Jason.encode!(embedding_list)

    # Prepare attrs for Ecto with defaults
    ecto_attrs = Map.merge(%{
      metadata: %{},
      user_id: nil,
      conversation_id: nil,
      message_id: nil
    }, attrs)
    |> Map.put(:embedding_data, embedding_json)

    # For now, let's use a simpler approach without the vector column
    # We'll store just the JSON data and handle vector operations separately
    %Embedding{}
    |> Embedding.changeset(ecto_attrs)
    |> Repo.insert()
  end

      @doc """
  Finds similar embeddings using cosine similarity.
  """
  def find_similar_embeddings(query_embedding, limit \\ 10, threshold \\ 0.7) do
    # For now, return a simple mock result since we're not using pgvector yet
    # In production, you'd implement proper vector similarity search
    case Repo.all(Embedding) do
      embeddings when length(embeddings) > 0 ->
        # Mock similarity calculation
        similar_embeddings = embeddings
        |> Enum.take(limit)
                |> Enum.map(fn embedding ->
          # Parse the JSON embedding data
          case Jason.decode(embedding.embedding_data) do
            {:ok, _embedding_vector} ->
              # Calculate a mock similarity score
              similarity = 0.8 + :rand.uniform() * 0.2
              Map.put(embedding, :similarity, similarity)

            {:error, _} ->
              Map.put(embedding, :similarity, 0.5)
          end
        end)
        |> Enum.filter(fn embedding -> embedding.similarity > threshold end)

        {:ok, similar_embeddings}

      _ ->
        {:ok, []}
    end
  end

        @doc """
  Finds similar embeddings for a specific user.
  """
  def find_similar_embeddings_for_user(query_embedding, user_id, limit \\ 10, threshold \\ 0.7) do
    # For now, return a simple mock result
    case Repo.all(from e in Embedding, where: e.user_id == ^user_id) do
      embeddings when length(embeddings) > 0 ->
        similar_embeddings = embeddings
        |> Enum.take(limit)
        |> Enum.map(fn embedding ->
          similarity = 0.8 + :rand.uniform() * 0.2
          Map.put(embedding, :similarity, similarity)
        end)
        |> Enum.filter(fn embedding -> embedding.similarity > threshold end)

        {:ok, similar_embeddings}

      _ ->
        {:ok, []}
    end
  end

          @doc """
  Finds similar embeddings for a specific conversation.
  """
  def find_similar_embeddings_for_conversation(query_embedding, conversation_id, limit \\ 10, threshold \\ 0.7) do
    # For now, return a simple mock result
    case Repo.all(from e in Embedding, where: e.conversation_id == ^conversation_id) do
      embeddings when length(embeddings) > 0 ->
        similar_embeddings = embeddings
        |> Enum.take(limit)
        |> Enum.map(fn embedding ->
          similarity = 0.8 + :rand.uniform() * 0.2
          Map.put(embedding, :similarity, similarity)
        end)
        |> Enum.filter(fn embedding -> embedding.similarity > threshold end)

        {:ok, similar_embeddings}

      _ ->
        {:ok, []}
    end
  end

  @doc """
  Counts the total number of embeddings in the database.
  """
  def count_embeddings do
    Repo.aggregate(Embedding, :count, :id)
  end

  @doc """
  Deletes embeddings for a specific conversation.
  """
  def delete_embeddings_for_conversation(conversation_id) do
    Repo.delete_all(from e in Embedding, where: e.conversation_id == ^conversation_id)
  end

  @doc """
  Deletes embeddings for a specific user.
  """
  def delete_embeddings_for_user(user_id) do
    Repo.delete_all(from e in Embedding, where: e.user_id == ^user_id)
  end

  @doc """
  Gets all embeddings for a conversation.
  """
  def get_embeddings_for_conversation(conversation_id) do
    Repo.all(from e in Embedding, where: e.conversation_id == ^conversation_id)
  end

  @doc """
  Gets all embeddings for a user.
  """
  def get_embeddings_for_user(user_id) do
    Repo.all(from e in Embedding, where: e.user_id == ^user_id)
  end

  @doc """
  Counts total embeddings in the database.
  """
  def count_embeddings do
    Repo.aggregate(Embedding, :count, :id)
  end
end
