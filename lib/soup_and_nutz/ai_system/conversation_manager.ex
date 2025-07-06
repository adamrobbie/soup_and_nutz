defmodule SoupAndNutz.AISystem.ConversationManager do
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_conversation(conversation_id) do
    GenServer.call(__MODULE__, {:get_conversation, conversation_id})
  end

  def save_message(conversation_id, message, response) do
    GenServer.cast(__MODULE__, {:save_message, conversation_id, message, response})
  end

  @impl true
  def init(_args) do
    # In production, you'd use a database like PostgreSQL or ETS
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_conversation, conversation_id}, _from, state) do
    conversation = Map.get(state, conversation_id, [])
    {:reply, conversation, state}
  end

  @impl true
  def handle_cast({:save_message, conversation_id, message, response}, state) do
    existing_conversation = Map.get(state, conversation_id, [])

    new_entry = %{
      timestamp: DateTime.utc_now(),
      message: message,
      response: response
    }

    updated_conversation = [new_entry | existing_conversation]
    new_state = Map.put(state, conversation_id, updated_conversation)

    {:noreply, new_state}
  end
end
