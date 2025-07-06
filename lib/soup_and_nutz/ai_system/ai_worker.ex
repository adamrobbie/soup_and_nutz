defmodule SoupAndNutz.AISystem.AIWorker do
  use GenServer, restart: :temporary

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message

  require Logger

  defstruct [:worker_id, :llm_chain, :config, :conversation_history]

  def start_link([worker_id, config]) do
    GenServer.start_link(__MODULE__, {worker_id, config},
      name: {:via, Registry, {SoupAndNutz.AISystem.WorkerRegistry, worker_id}})
  end

  def process_message(worker_id, message, context \\ %{}) do
    case Registry.lookup(SoupAndNutz.AISystem.WorkerRegistry, worker_id) do
      [{pid, _}] -> GenServer.call(pid, {:process_message, message, context})
      [] -> {:error, :worker_not_found}
    end
  end

    @impl true
  def init({worker_id, config}) do
    # Initialize LangChain with circuit breaker protection
    llm_config = Map.get(config, :llm, %{})

    # Provide default configuration if none provided
    default_config = %{
      model: "gpt-3.5-turbo",
      temperature: 0.7
    }

    final_llm_config = Map.merge(default_config, llm_config)

    llm_chain = LLMChain.new!(%{
      llm: ChatOpenAI.new!(final_llm_config),
      verbose: Map.get(config, :verbose, false)
    })

    state = %__MODULE__{
      worker_id: worker_id,
      llm_chain: llm_chain,
      config: config,
      conversation_history: []
    }

    Logger.info("AI Worker #{worker_id} started")
    {:ok, state}
  end

  @impl true
  def handle_call({:process_message, message, context}, _from, state) do
    # Use circuit breaker for AI service calls
    result = SoupAndNutz.AISystem.CircuitBreaker.call_ai_service(fn ->
      process_with_langchain(message, context, state)
    end)

    case result do
      {:ok, {response, updated_chain}} ->
        new_state = %{state |
          llm_chain: updated_chain,
          conversation_history: [message | state.conversation_history]
        }
        {:reply, {:ok, response}, new_state}

      {:error, reason} ->
        Logger.error("AI processing failed for worker #{state.worker_id}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error("AI Worker #{state.worker_id} received EXIT signal: #{inspect(reason)}")
    {:stop, reason, state}
  end

  defp process_with_langchain(message, context, state) do
    # Add custom functions if provided in context
    chain_with_message = state.llm_chain
    |> add_custom_functions(Map.get(context, :functions, []))
    |> LLMChain.add_message(Message.new_user!(message))

    case LLMChain.run(chain_with_message, mode: :while_needs_response) do
      {:ok, updated_chain} ->
        # Get the last message from the chain
        messages = Map.get(updated_chain, :messages, [])
        response = case List.last(messages) do
          %{content: content} -> content
          _ -> "No response content available"
        end
        {response, updated_chain}
      {:error, reason} ->
        raise "LangChain processing failed: #{inspect(reason)}"
    end
  end

  defp add_custom_functions(chain, []), do: chain
  defp add_custom_functions(chain, functions) do
    Enum.reduce(functions, chain, fn func, acc_chain ->
      LLMChain.add_tools(acc_chain, func)
    end)
  end
end
