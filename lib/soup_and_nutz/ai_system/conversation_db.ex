defmodule SoupAndNutz.AISystem.ConversationDB do
  @moduledoc """
  Context module for conversation and message database operations.
  """

  alias SoupAndNutz.Repo
  alias SoupAndNutz.AISystem.{Conversation, Message}

  @doc """
  Gets a conversation by its external ID, preloading messages.
  """
  def get_conversation_by_external_id(external_id) do
    Repo.get_by(Conversation, external_id: external_id)
    |> Repo.preload(:messages)
  end

  @doc """
  Gets or creates a conversation by external ID.
  """
  def get_or_create_conversation(external_id) do
    case get_conversation_by_external_id(external_id) do
      nil ->
        case create_conversation(%{external_id: external_id}) do
          {:ok, conversation} -> Repo.preload(conversation, :messages)
          {:error, _} -> nil
        end
      conversation -> conversation
    end
  end

  @doc """
  Creates a new conversation.
  """
  def create_conversation(attrs) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Adds a message to a conversation.
  """
  def add_message(conversation, attrs) do
    %Message{}
    |> Message.changeset(Map.put(attrs, :conversation_id, conversation.id))
    |> Repo.insert()
  end

  @doc """
  Lists all messages for a conversation.
  """
  def list_messages(conversation) do
    Repo.preload(conversation, :messages).messages
  end

  @doc """
  Gets all conversations with their message counts.
  """
  def list_conversations do
    Conversation
    |> Repo.all()
    |> Repo.preload(:messages)
  end

  @doc """
  Deletes a conversation and all its messages.
  """
  def delete_conversation(conversation) do
    Repo.delete(conversation)
  end
end
