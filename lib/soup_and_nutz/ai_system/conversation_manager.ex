defmodule SoupAndNutz.AISystem.ConversationManager do
  use GenServer
  require Logger

  alias SoupAndNutz.AISystem.{ConversationDB, EmbeddingService}

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_conversation(conversation_id) do
    GenServer.call(__MODULE__, {:get_conversation, conversation_id})
  end

  def save_message(conversation_id, role, content, user_id \\ nil) do
    GenServer.cast(__MODULE__, {:save_message, conversation_id, role, content, user_id})
  end

  @impl true
  def init(_args) do
    Logger.info("ConversationManager started with PostgreSQL backend")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_conversation, conversation_id}, _from, state) do
    conversation = ConversationDB.get_conversation_by_external_id(conversation_id)
    {:reply, conversation, state}
  end

    @impl true
  def handle_cast({:save_message, conversation_id, role, content, user_id}, state) do
    conversation = ConversationDB.get_or_create_conversation(conversation_id)

    if conversation do
      case ConversationDB.add_message(conversation, %{role: role, content: content}) do
        {:ok, message} ->
          Logger.debug("Saved message for conversation #{conversation_id}")

          # Store embedding for the message if user_id is provided
          if user_id do
            Task.start(fn ->
              EmbeddingService.process_message_embedding(content, user_id, conversation.id, message.id)
            end)
          end

        {:error, reason} ->
          Logger.error("Failed to save message for conversation #{conversation_id}: #{inspect(reason)}")
      end
    else
      Logger.error("Failed to get or create conversation #{conversation_id}")
    end

    {:noreply, state}
  end
end
