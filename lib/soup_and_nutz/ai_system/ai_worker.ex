defmodule SoupAndNutz.AISystem.AIWorker do
  use GenServer, restart: :temporary

  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias SoupAndNutz.AISystem.ModelProvider
  alias SoupAndNutz.AISystem.PromptManager

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
    # Get user ID from config for model selection
    user_id = Map.get(config, :user_id)

    # Get model from ModelProvider (with user preference support)
    case ModelProvider.get_model(user_id) do
      {:ok, llm} ->
        llm_chain = LLMChain.new!(%{
          llm: llm,
          verbose: Map.get(config, :verbose, false)
        })

        state = %__MODULE__{
          worker_id: worker_id,
          llm_chain: llm_chain,
          config: config,
          conversation_history: []
        }

        Logger.info("AI Worker #{worker_id} started with user #{user_id}")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to initialize AI Worker #{worker_id}: #{reason}")
        {:stop, reason}
    end
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
    # Create a structured prompt using our prompt templates
    case PromptManager.create_prompt(message, context) do
      {:ok, formatted_prompt, template_type} ->
        Logger.info("Using #{template_type} prompt template for message: #{String.slice(message, 0, 50)}...")

        # Add custom functions if provided in context
        chain_with_message = state.llm_chain
        |> add_custom_functions(Map.get(context, :functions, []))
        |> LLMChain.add_message(Message.new_user!(formatted_prompt))

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

      {:error, reason} ->
        Logger.warning("Failed to create prompt template, falling back to direct message: #{reason}")

        # Fallback to original behavior
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
  end

  defp add_custom_functions(chain, []), do: chain
  defp add_custom_functions(chain, functions) do
    Enum.reduce(functions, chain, fn func, acc_chain ->
      LLMChain.add_tools(acc_chain, func)
    end)
  end
end
