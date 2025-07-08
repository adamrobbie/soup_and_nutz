defmodule SoupAndNutz.MCP.Supervisor do
  @moduledoc """
  Supervisor for the MCP (Model Context Protocol) server.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Get port from environment variable or default to 3002
    port = case System.get_env("MCP_PORT") do
      nil -> Keyword.get(opts, :port, 3002)
      port_str -> String.to_integer(port_str)
    end

    children = [
      {SoupAndNutz.MCP.Server, [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
