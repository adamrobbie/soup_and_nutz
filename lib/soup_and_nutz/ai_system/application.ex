defmodule SoupAndNutz.AISystem.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Core AI services supervision tree
      SoupAndNutz.AISystem.AISupervisor,

      # Optional: Web interface integration
      # {Phoenix.PubSub, name: SoupAndNutz.AISystem.PubSub},
      # SoupAndNutzWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SoupAndNutz.AISystem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
