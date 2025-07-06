defmodule SoupAndNutz.AISystem.CircuitBreaker do
  use GenServer
  require Logger

  defstruct [:failure_count, :state, :last_failure_time, :timeout]

  @failure_threshold 5
  @recovery_timeout 30_000 # 30 seconds

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def call_ai_service(service_call) do
    GenServer.call(__MODULE__, {:call_service, service_call})
  end

  @impl true
  def init(_args) do
    state = %__MODULE__{
      failure_count: 0,
      state: :closed,
      last_failure_time: nil,
      timeout: @recovery_timeout
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:call_service, service_call}, _from, %{state: :open} = state) do
    if should_attempt_reset?(state) do
      try_service_call(service_call, %{state | state: :half_open})
    else
      {:reply, {:error, :circuit_breaker_open}, state}
    end
  end

  def handle_call({:call_service, service_call}, _from, state) do
    try_service_call(service_call, state)
  end

  defp try_service_call(service_call, state) do
    try do
      result = service_call.()
      new_state = %{state | failure_count: 0, state: :closed}
      {:reply, {:ok, result}, new_state}
    rescue
      error ->
        Logger.error("AI service call failed: #{inspect(error)}")
        new_failure_count = state.failure_count + 1

        new_state = %{state |
          failure_count: new_failure_count,
          last_failure_time: System.monotonic_time(:millisecond),
          state: if(new_failure_count >= @failure_threshold, do: :open, else: state.state)
        }

        {:reply, {:error, error}, new_state}
    end
  end

  defp should_attempt_reset?(%{last_failure_time: last_failure, timeout: timeout}) do
    System.monotonic_time(:millisecond) - last_failure > timeout
  end
end
