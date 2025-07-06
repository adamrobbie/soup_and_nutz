defmodule SoupAndNutz.AISystem.AISupervisor do
  use Supervisor

  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      # Circuit breaker for AI service failures
      SoupAndNutz.AISystem.CircuitBreaker,

      # Pool of AI workers for load balancing
      {Registry, keys: :unique, name: SoupAndNutz.AISystem.WorkerRegistry},
      SoupAndNutz.AISystem.AIWorkerSupervisor,

      # Message routing and orchestration
      SoupAndNutz.AISystem.MessageRouter,

      # Persistent conversation manager
      SoupAndNutz.AISystem.ConversationManager,

      # Health monitoring
      SoupAndNutz.AISystem.HealthMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
