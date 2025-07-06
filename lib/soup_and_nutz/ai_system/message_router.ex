defmodule SoupAndNutz.AISystem.MessageRouter do
  use GenServer
  require Logger

  defstruct [:worker_pool, :round_robin_index]

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def route_message(message, context \\ %{}) do
    GenServer.call(__MODULE__, {:route_message, message, context})
  end

  @impl true
  def init(_args) do
    # Start initial worker pool
    worker_ids = for i <- 1..3, do: "worker_#{i}"

    Enum.each(worker_ids, fn worker_id ->
      SoupAndNutz.AISystem.AIWorkerSupervisor.start_worker(worker_id)
    end)

    state = %__MODULE__{
      worker_pool: worker_ids,
      round_robin_index: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:route_message, message, context}, _from, state) do
    worker_id = get_next_worker(state)

    result = SoupAndNutz.AISystem.AIWorker.process_message(worker_id, message, context)

    new_state = %{state |
      round_robin_index: rem(state.round_robin_index + 1, length(state.worker_pool))
    }

    {:reply, result, new_state}
  end

  defp get_next_worker(state) do
    Enum.at(state.worker_pool, state.round_robin_index)
  end
end
