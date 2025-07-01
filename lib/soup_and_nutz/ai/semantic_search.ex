defmodule SoupAndNutz.AI.SemanticSearch do
  @moduledoc """
  Service for semantic search of financial instruments and conversations using vector similarity.
  """

  import Ecto.Query
  alias SoupAndNutz.Repo
  alias SoupAndNutz.FinancialInstruments.Asset
  alias SoupAndNutz.FinancialInstruments.DebtObligation
  alias SoupAndNutz.AI.{OpenAIService, ConversationMemory}


  @doc """
  Searches for assets similar to the given query.
  """
  def search_assets(query, user_id, limit \\ 10) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      case OpenAIService.generate_embedding(query) do
        {:ok, embedding} ->
          from(a in Asset,
            where: a.user_id == ^user_id and not is_nil(a.embedding),
            order_by: [desc: fragment("embedding <=> ?", ^embedding)],
            limit: ^limit
          )
          |> Repo.all()

        {:error, error} ->
          {:error, "Failed to generate embedding for search: #{inspect(error)}"}
      end
    else
      # In test mode, return empty list since no embeddings are generated
      []
    end
  end

  @doc """
  Searches for debt obligations similar to the given query.
  """
  def search_debts(query, user_id, limit \\ 10) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      case OpenAIService.generate_embedding(query) do
        {:ok, embedding} ->
          from(d in DebtObligation,
            where: d.user_id == ^user_id and not is_nil(d.embedding),
            order_by: [desc: fragment("embedding <=> ?", ^embedding)],
            limit: ^limit
          )
          |> Repo.all()

        {:error, error} ->
          {:error, "Failed to generate embedding for search: #{inspect(error)}"}
      end
    else
      # In test mode, return empty list since no embeddings are generated
      []
    end
  end

  @doc """
  Searches for both assets and debts similar to the given query.
  Returns a combined list with type indicators.
  """
  def search_all(query, user_id, limit \\ 10) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      with {:ok, assets} <- search_assets(query, user_id, limit),
           {:ok, debts} <- search_debts(query, user_id, limit) do

        combined =
          (assets |> Enum.map(&Map.put(&1, :type, :asset))) ++
          (debts |> Enum.map(&Map.put(&1, :type, :debt)))

        # Sort by similarity (assuming both have embedding distance)
        {:ok, Enum.take(combined, limit)}
      else
        {:error, error} -> {:error, error}
      end
    else
      # In test mode, return empty list since no embeddings are generated
      {:ok, []}
    end
  end

  @doc """
  Finds assets similar to a given asset.
  """
  def find_similar_assets(asset, user_id, limit \\ 5) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) and asset.embedding do
      from(a in Asset,
        where: a.user_id == ^user_id and a.id != ^asset.id and not is_nil(a.embedding),
        order_by: [desc: fragment("embedding <=> ?", ^asset.embedding)],
        limit: ^limit
      )
      |> Repo.all()
    else
      []
    end
  end

  @doc """
  Finds debt obligations similar to a given debt obligation.
  """
  def find_similar_debts(debt, user_id, limit \\ 5) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) and debt.embedding do
      from(d in DebtObligation,
        where: d.user_id == ^user_id and d.id != ^debt.id and not is_nil(d.embedding),
        order_by: [desc: fragment("embedding <=> ?", ^debt.embedding)],
        limit: ^limit
      )
      |> Repo.all()
    else
      []
    end
  end

  @doc """
  Gets recommendations based on user's financial profile.
  """
  def get_recommendations(user_id, limit \\ 5) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      # Get user's assets and debts
      assets = Repo.all(from a in Asset, where: a.user_id == ^user_id)
      debts = Repo.all(from d in DebtObligation, where: d.user_id == ^user_id)

      # Generate profile embedding
      profile_text = build_profile_text(assets, debts)

      case OpenAIService.generate_embedding(profile_text) do
        {:ok, embedding} ->
          # Find similar items from other users (anonymized)
          similar_assets =
            from(a in Asset,
              where: a.user_id != ^user_id and not is_nil(a.embedding),
              order_by: [desc: fragment("embedding <=> ?", ^embedding)],
              limit: ^limit
            )
            |> Repo.all()

          similar_debts =
            from(d in DebtObligation,
              where: d.user_id != ^user_id and not is_nil(d.embedding),
              order_by: [desc: fragment("embedding <=> ?", ^embedding)],
              limit: ^limit
            )
            |> Repo.all()

          {:ok, %{assets: similar_assets, debts: similar_debts}}

        {:error, error} ->
          {:error, "Failed to generate profile embedding: #{inspect(error)}"}
      end
    else
      # In test mode, return empty recommendations
      {:ok, %{assets: [], debts: []}}
    end
  end

  @doc """
  Searches for conversations similar to the given query.
  """
  def search_conversations(query, user_id, limit \\ 5) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      case OpenAIService.generate_embedding(query) do
        {:ok, embedding} ->
          # Get conversation memories with embeddings
          memories = from(m in ConversationMemory,
            where: m.user_id == ^user_id and not is_nil(m.embedding),
            order_by: [desc: fragment("embedding <=> ?", ^embedding)],
            limit: ^limit
          )
          |> Repo.all()

          # Group by conversation_id and return conversation summaries
          conversations = memories
          |> Enum.group_by(& &1.conversation_id)
          |> Enum.map(fn {conversation_id, memories} ->
            %{
              conversation_id: conversation_id,
              memories: memories,
              summary: summarize_conversation(memories),
              relevance_score: calculate_relevance_score(memories, embedding)
            }
          end)
          |> Enum.sort_by(& &1.relevance_score, :desc)
          |> Enum.take(limit)

          {:ok, conversations}

        {:error, error} ->
          {:error, "Failed to generate embedding for conversation search: #{inspect(error)}"}
      end
    else
      # In test mode, return empty list since no embeddings are generated
      {:ok, []}
    end
  end

  @doc """
  Finds conversations similar to a given conversation.
  """
  def find_similar_conversations(conversation_id, user_id, limit \\ 3) do
    if Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      # Get the target conversation's embedding
      target_memory = from(m in ConversationMemory,
        where: m.conversation_id == ^conversation_id and m.user_id == ^user_id and not is_nil(m.embedding),
        limit: 1
      )
      |> Repo.one()

      if target_memory do
        # Find similar conversations
        similar_memories = from(m in ConversationMemory,
          where: m.user_id == ^user_id and m.conversation_id != ^conversation_id and not is_nil(m.embedding),
          order_by: [desc: fragment("embedding <=> ?", ^target_memory.embedding)],
          limit: ^limit
        )
        |> Repo.all()

        # Group by conversation_id
        conversations = similar_memories
        |> Enum.group_by(& &1.conversation_id)
        |> Enum.map(fn {conv_id, memories} ->
          %{
            conversation_id: conv_id,
            memories: memories,
            summary: summarize_conversation(memories),
            similarity_score: calculate_similarity_score(memories, target_memory.embedding)
          }
        end)
        |> Enum.sort_by(& &1.similarity_score, :desc)

        {:ok, conversations}
      else
        {:ok, []}
      end
    else
      # In test mode, return empty list
      {:ok, []}
    end
  end

  @doc """
  Gets conversation context for a specific conversation with semantic relevance.
  """
  def get_conversation_context_with_relevance(conversation_id, _user_id, query \\ nil) do
    memories = ConversationMemory.get_conversation_context(conversation_id)

    if query && Application.get_env(:soup_and_nutz, :enable_embeddings, true) do
      # Calculate relevance to the query
      case OpenAIService.generate_embedding(query) do
        {:ok, embedding} ->
          memories_with_relevance = Enum.map(memories, fn memory ->
            relevance = if memory.embedding do
              calculate_relevance_score([memory], embedding)
            else
              0.5
            end
            Map.put(memory, :relevance_score, relevance)
          end)
          |> Enum.sort_by(& &1.relevance_score, :desc)

          {:ok, memories_with_relevance}

        {:error, _} ->
          {:ok, memories}
      end
    else
      {:ok, memories}
    end
  end

  # Private functions

  defp build_profile_text(assets, debts) do
    asset_summary =
      assets
      |> Enum.map(fn asset -> "#{asset.asset_type}: #{asset.asset_name}" end)
      |> Enum.join(", ")

    debt_summary =
      debts
      |> Enum.map(fn debt -> "#{debt.debt_type}: #{debt.debt_name}" end)
      |> Enum.join(", ")

    """
    Financial Profile:
    Assets: #{asset_summary}
    Debts: #{debt_summary}
    """
  end

  @doc """
  Summarizes a conversation based on its memories.
  """
  def summarize_conversation(memories) do
    # Extract key topics and actions
    topics = extract_conversation_topics(memories)
    actions = extract_conversation_actions(memories)

    summary = case {topics, actions} do
      {[], []} -> "General conversation"
      {topics, []} -> "Topics: #{Enum.join(topics, ", ")}"
      {[], actions} -> "Actions: #{Enum.join(actions, ", ")}"
      {topics, actions} -> "Topics: #{Enum.join(topics, ", ")} | Actions: #{Enum.join(actions, ", ")}"
    end

    %{
      summary: summary,
      topics: topics,
      actions: actions,
      message_count: length(memories),
      last_activity: get_last_activity(memories)
    }
  end

  @doc """
  Extracts topics from conversation memories.
  """
  def extract_conversation_topics(memories) do
    # Use OpenAI to extract topics from conversation text
    text = memories
    |> Enum.map(fn memory -> memory.message end)
    |> Enum.join(" ")

    if String.length(text) > 0 do
      case apply(OpenAIService.openai_client(), :chat_completion, [
        [
          model: "gpt-4",
          messages: [
            %{role: "system", content: "Extract main topics from the conversation. Return as comma-separated list."},
            %{role: "user", content: "Extract topics from: #{text}"}
          ],
          temperature: 0.1
        ]
      ]) do
        {:ok, response} ->
          case response.choices do
            [%{message: %{content: content}} | _] ->
              content
              |> String.split(",")
              |> Enum.map(&String.trim/1)
              |> Enum.filter(&(&1 != ""))
            _ -> []
          end
        {:error, _} -> []
      end
    else
      []
    end
  end

  @doc """
  Extracts actions from conversation memories.
  """
  def extract_conversation_actions(memories) do
    memories
    |> Enum.map(fn memory -> memory.action_taken end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.uniq()
  end

  @doc """
  Gets the last activity timestamp from conversation memories.
  """
  def get_last_activity(memories) do
    memories
    |> Enum.max_by(& &1.inserted_at, fn -> nil end)
    |> case do
      nil -> nil
      memory -> memory.inserted_at
    end
  end

  @doc """
  Calculates relevance score for memories against a query embedding.
  """
  def calculate_relevance_score(memories, query_embedding) do
    # Calculate average similarity score
    scores = memories
    |> Enum.map(fn memory ->
      if memory.embedding do
        calculate_cosine_similarity(memory.embedding, query_embedding)
      else
        0.5
      end
    end)

    case scores do
      [] -> 0.0
      scores -> Enum.sum(scores) / length(scores)
    end
  end

  @doc """
  Calculates similarity score for memories against a target embedding.
  """
  def calculate_similarity_score(memories, target_embedding) do
    calculate_relevance_score(memories, target_embedding)
  end

  @doc """
  Calculates cosine similarity between two embeddings.
  """
  def calculate_cosine_similarity(_embedding1, _embedding2) do
    # This is a simplified cosine similarity calculation
    # In a real implementation, you'd use a proper vector similarity function
    # For now, we'll use a placeholder that returns a value between 0 and 1
    :rand.uniform()
  end
end
