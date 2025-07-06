defmodule SoupAndNutz.AISystem.HealthMonitor do
  use GenServer
  require Logger

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_system_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def init(_args) do
    # Schedule periodic health checks
    :timer.send_interval(30_000, :health_check)
    {:ok, %{last_check: DateTime.utc_now(), status: :healthy}}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:health_check, state) do
    status = perform_health_check()
    new_state = %{state | last_check: DateTime.utc_now(), status: status}

    if status != :healthy do
      Logger.warning("System health check failed: #{status}")
    end

    {:noreply, new_state}
  end

  defp perform_health_check do
    # Check if core processes are alive
    processes_to_check = [
      SoupAndNutz.AISystem.CircuitBreaker,
      SoupAndNutz.AISystem.MessageRouter,
      SoupAndNutz.AISystem.ConversationManager
    ]

    all_healthy = Enum.all?(processes_to_check, fn process ->
      Process.whereis(process) != nil and Process.alive?(Process.whereis(process))
    end)

    if all_healthy, do: :healthy, else: :unhealthy
  end
end
