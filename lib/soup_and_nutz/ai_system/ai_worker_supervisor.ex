defmodule SoupAndNutz.AISystem.AIWorkerSupervisor do
  use DynamicSupervisor

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 10)
  end

  def start_worker(worker_id, config \\ %{}) do
    child_spec = {SoupAndNutz.AISystem.AIWorker, [worker_id, config]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_worker(worker_id) do
    case Registry.lookup(SoupAndNutz.AISystem.WorkerRegistry, worker_id) do
      [{pid, _}] ->
        case DynamicSupervisor.terminate_child(__MODULE__, pid) do
          :ok -> {:ok, pid}
          error -> error
        end
      [] -> {:error, :not_found}
    end
  end
end
