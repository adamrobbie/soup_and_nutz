defmodule SoupAndNutz.AISystem.VectorDBTest do
  use ExUnit.Case, async: false
  use SoupAndNutz.DataCase

  alias SoupAndNutz.AISystem.{VectorDB, EmbeddingService}

  describe "vector database operations" do
    test "can store and retrieve embeddings without foreign keys" do
      # Generate a test embedding
      test_content = "This is a test message for vector storage"
      {:ok, embedding} = EmbeddingService.generate_embedding(test_content)

      # Store the embedding without foreign keys
      attrs = %{
        content: test_content,
        embedding: embedding,
        metadata: %{"type" => "test"}
      }

      case VectorDB.store_embedding(attrs) do
        {:ok, stored_embedding} ->
          assert stored_embedding.content == test_content
          assert stored_embedding.embedding_data == Jason.encode!(embedding)
          assert stored_embedding.metadata == %{"type" => "test"}

        {:error, reason} ->
          flunk("Failed to store embedding: #{inspect(reason)}")
      end
    end

    test "can find similar embeddings" do
      # Store multiple embeddings
      contents = [
        "I love programming in Elixir",
        "Elixir is a functional programming language",
        "Phoenix framework is great for web development",
        "The weather is nice today",
        "I enjoy reading books"
      ]

      embeddings = Enum.map(contents, fn content ->
        {:ok, embedding} = EmbeddingService.generate_embedding(content)
        attrs = %{
          content: content,
          embedding: embedding,
          metadata: %{"type" => "test"}
        }
        VectorDB.store_embedding(attrs)
      end)

      # All embeddings should be stored successfully
      Enum.each(embeddings, fn
        {:ok, _} -> :ok
        {:error, reason} -> flunk("Failed to store embedding: #{inspect(reason)}")
      end)

      # Find similar embeddings
      query_content = "I like coding in Elixir"
      {:ok, query_embedding} = EmbeddingService.generate_embedding(query_content)

      case VectorDB.find_similar_embeddings(query_embedding, 3, 0.5) do
        {:ok, similar_embeddings} ->
          assert length(similar_embeddings) > 0
          # The first result should have the highest similarity
          [first_result | _] = similar_embeddings
          assert Map.has_key?(first_result, :similarity)

        {:error, reason} ->
          flunk("Failed to find similar embeddings: #{inspect(reason)}")
      end
    end

    test "can count total embeddings" do
      count = VectorDB.count_embeddings()
      assert is_integer(count)
      assert count >= 0
    end
  end

  describe "embedding service" do
    test "can generate embeddings" do
      text = "Hello, world!"
      {:ok, embedding} = EmbeddingService.generate_embedding(text)

      assert is_list(embedding)
      assert length(embedding) == 1536  # OpenAI embedding dimensions
      assert Enum.all?(embedding, &is_float/1)
    end

    test "can store embeddings without context" do
      message_content = "This is a test message"
      {:ok, embedding} = EmbeddingService.generate_embedding(message_content)

      case EmbeddingService.store_embedding(message_content, embedding, %{"type" => "test"}) do
        {:ok, stored_embedding} ->
          assert stored_embedding.content == message_content
          assert stored_embedding.embedding_data == Jason.encode!(embedding)
          assert stored_embedding.metadata == %{"type" => "test"}

        {:error, reason} ->
          flunk("Failed to store embedding: #{inspect(reason)}")
      end
    end
  end
end
