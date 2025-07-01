defmodule SoupAndNutz.AI.ConversationMemory do
  @moduledoc """
  Manages conversation context and memory for RAG interactions.
  Maintains conversation history and extracts key information for context.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias SoupAndNutz.Repo

  schema "conversation_memories" do
    belongs_to :user, SoupAndNutz.Accounts.User

    field :conversation_id, :string
    field :message, :string
    field :response, :string
    field :extracted_data, :map
    field :confidence, :float
    field :action_taken, :string  # "asset_created", "debt_created", "query", "error"
    field :context_summary, :string
    field :entities, :map  # Extracted entities like amounts, dates, names
    field :embedding, {:array, :float}  # Vector embedding for semantic search

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation_memory, attrs) do
    conversation_memory
    |> cast(attrs, [
      :user_id, :conversation_id, :message, :response, :extracted_data,
      :confidence, :action_taken, :context_summary, :entities, :embedding
    ])
    |> validate_required([:user_id, :conversation_id, :message])
    |> validate_inclusion(:action_taken, ["asset_created", "debt_created", "query", "error", nil])
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
  end

  @doc """
  Creates a new conversation memory entry.
  """
  def create_memory(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets recent conversation context for a user.
  """
  def get_recent_context(user_id, limit \\ 10) do
    from(m in __MODULE__,
      where: m.user_id == ^user_id,
      order_by: [desc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets conversation context by conversation ID.
  """
  def get_conversation_context(conversation_id) do
    from(m in __MODULE__,
      where: m.conversation_id == ^conversation_id,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Summarizes conversation context for AI processing.
  """
  def summarize_context(memories) do
    memories
    |> Enum.map(fn memory ->
      """
      Message: #{memory.message}
      Action: #{memory.action_taken || "none"}
      Entities: #{inspect(memory.entities)}
      """
    end)
    |> Enum.join("\n")
  end

  @doc """
  Extracts key entities from conversation history.
  """
  def extract_entities(memories) do
    memories
    |> Enum.flat_map(fn memory ->
      case memory.entities do
        %{} = entities -> Map.to_list(entities)
        _ -> []
      end
    end)
    |> Enum.group_by(fn {key, _} -> key end, fn {_, value} -> value end)
    |> Map.new(fn {key, values} -> {key, Enum.uniq(values)} end)
  end

  @doc """
  Cleans up old conversation memories (older than 30 days).
  """
  def cleanup_old_memories do
    thirty_days_ago = DateTime.utc_now() |> DateTime.add(-30 * 24 * 60 * 60, :second)

    from(m in __MODULE__,
      where: m.inserted_at < ^thirty_days_ago
    )
    |> Repo.delete_all()
  end

  @doc """
  Generates a conversation ID for tracking related interactions.
  """
  def generate_conversation_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Returns a list of recent conversation memories for a user (stub for tests).
  """
  def list_recent_memories_by_user(_user_id, _limit), do: []
end
