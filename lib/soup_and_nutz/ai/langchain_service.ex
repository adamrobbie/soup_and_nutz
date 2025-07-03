defmodule SoupAndNutz.AI.LangChainService do
  @moduledoc """
  Advanced LangChain service providing sophisticated AI capabilities with
  dynamic model selection, prompt engineering, and financial domain expertise.
  """

  use GenServer
  require Logger

  alias SoupAndNutz.AI.PromptEngine
  alias SoupAndNutz.AI.ModelManager
  alias SoupAndNutz.AI.RAGChain
  alias SoupAndNutz.AI.ConversationMemory
  alias SoupAndNutz.AI.FinancialAgent

  defstruct [
    :current_model,
    :conversation_memory,
    :rag_chain,
    :prompt_engine,
    :model_manager,
    :config
  ]

  # Client API

  @doc """
  Start the LangChain service with configuration options.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Process a chat message with context-aware response generation.
  """
  def chat(message, user_id, options \\ []) do
    GenServer.call(__MODULE__, {:chat, message, user_id, options}, 30_000)
  end

  @doc """
  Switch to a different model dynamically.
  """
  def switch_model(model_name) when is_binary(model_name) do
    GenServer.call(__MODULE__, {:switch_model, model_name})
  end

  @doc """
  Get available models from all providers.
  """
  def list_available_models() do
    GenServer.call(__MODULE__, :list_available_models)
  end

  @doc """
  Create a financial analysis chain for specialized financial tasks.
  """
  def create_financial_chain(analysis_type, user_data) do
    GenServer.call(__MODULE__, {:create_financial_chain, analysis_type, user_data})
  end

  @doc """
  Execute a RAG query with financial context.
  """
  def rag_query(query, user_id, options \\ []) do
    GenServer.call(__MODULE__, {:rag_query, query, user_id, options})
  end

  # Server Implementation

  @impl true
  def init(opts) do
    config = build_config(opts)
    
    state = %__MODULE__{
      config: config,
      model_manager: ModelManager.new(config.providers),
      prompt_engine: PromptEngine.new(),
      conversation_memory: ConversationMemory.new(),
      rag_chain: RAGChain.new(config.rag_config)
    }

    # Initialize with default model
    case ModelManager.get_default_model(state.model_manager) do
      {:ok, model} ->
        {:ok, %{state | current_model: model}}
      {:error, reason} ->
        Logger.error("Failed to initialize default model: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_call({:chat, message, user_id, options}, _from, state) do
    try do
      # Build conversation context
      context = build_conversation_context(message, user_id, options, state)
      
      # Generate response using current model
      response = generate_response(context, state)
      
      # Store conversation in memory
      updated_memory = ConversationMemory.add_exchange(
        state.conversation_memory,
        user_id,
        message,
        response
      )

      new_state = %{state | conversation_memory: updated_memory}
      {:reply, {:ok, response}, new_state}
    rescue
      error ->
        Logger.error("Error in chat processing: #{inspect(error)}")
        {:reply, {:error, "Failed to process chat message"}, state}
    end
  end

  @impl true
  def handle_call({:switch_model, model_name}, _from, state) do
    case ModelManager.switch_model(state.model_manager, model_name) do
      {:ok, new_model} ->
        Logger.info("Switched to model: #{model_name}")
        new_state = %{state | current_model: new_model}
        {:reply, {:ok, new_model}, new_state}
      {:error, reason} ->
        Logger.warning("Failed to switch to model #{model_name}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:list_available_models, _from, state) do
    models = ModelManager.list_available_models(state.model_manager)
    {:reply, {:ok, models}, state}
  end

  @impl true
  def handle_call({:create_financial_chain, analysis_type, user_data}, _from, state) do
    try do
      chain = FinancialAgent.create_specialized_chain(analysis_type, user_data, state.current_model)
      {:reply, {:ok, chain}, state}
    rescue
      error ->
        Logger.error("Error creating financial chain: #{inspect(error)}")
        {:reply, {:error, "Failed to create financial chain"}, state}
    end
  end

  @impl true
  def handle_call({:rag_query, query, user_id, options}, _from, state) do
    try do
      # Enhance query with user context
      enhanced_query = enhance_query_with_context(query, user_id, options)
      
      # Execute RAG chain
      result = RAGChain.query(state.rag_chain, enhanced_query, state.current_model)
      
      {:reply, {:ok, result}, state}
    rescue
      error ->
        Logger.error("Error in RAG query: #{inspect(error)}")
        {:reply, {:error, "Failed to execute RAG query"}, state}
    end
  end

  # Private Functions

  defp build_config(opts) do
    default_config = %{
      providers: %{
        ollama: %{
          base_url: System.get_env("OLLAMA_BASE_URL") || "http://localhost:11434",
          default_model: "llama3.1:8b",
          available_models: ["llama3.1:8b", "mistral:7b", "codellama:13b", "phi3:mini"]
        },
        openai: %{
          api_key: System.get_env("OPENAI_API_KEY"),
          default_model: "gpt-4o-mini",
          available_models: ["gpt-4o", "gpt-4o-mini", "gpt-3.5-turbo"]
        },
        anthropic: %{
          api_key: System.get_env("ANTHROPIC_API_KEY"),
          default_model: "claude-3-sonnet-20240229",
          available_models: ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
        }
      },
      rag_config: %{
        embedding_model: "text-embedding-3-small",
        chunk_size: 1000,
        chunk_overlap: 200,
        top_k: 5
      },
      default_provider: :ollama
    }

    deep_merge(default_config, Enum.into(opts, %{}))
  end

  defp build_conversation_context(message, user_id, options, state) do
    %{
      message: message,
      user_id: user_id,
      conversation_history: ConversationMemory.get_recent_history(state.conversation_memory, user_id, 10),
      financial_context: get_financial_context(user_id),
      prompt_strategy: Keyword.get(options, :prompt_strategy, :conversational),
      temperature: Keyword.get(options, :temperature, 0.7),
      max_tokens: Keyword.get(options, :max_tokens, 1000)
    }
  end

  defp generate_response(context, state) do
    # Generate prompt using prompt engine
    prompt = PromptEngine.generate_prompt(
      state.prompt_engine,
      context.prompt_strategy,
      context
    )

    # Generate response using current model
    case state.current_model do
      %{provider: provider} = model ->
        generate_with_provider(provider, model, prompt, context)
      nil ->
        {:error, "No model available"}
    end
  end

  defp generate_with_provider(:ollama, model, prompt, context) do
    SoupAndNutz.AI.OllamaProvider.generate(model, prompt, context)
  end

  defp generate_with_provider(:openai, model, prompt, context) do
    SoupAndNutz.AI.OpenAIProvider.generate(model, prompt, context)
  end

  defp generate_with_provider(:anthropic, model, prompt, context) do
    SoupAndNutz.AI.AnthropicProvider.generate(model, prompt, context)
  end

  defp get_financial_context(user_id) do
    # Fetch user's financial data for context
    %{
      assets: SoupAndNutz.FinancialInstruments.list_assets_for_user(user_id),
      debts: SoupAndNutz.FinancialInstruments.list_debt_obligations_for_user(user_id),
      goals: SoupAndNutz.FinancialGoals.list_goals_for_user(user_id),
      net_worth: SoupAndNutz.FinancialInstruments.calculate_net_worth(user_id)
    }
  rescue
    _ -> %{}
  end

  defp enhance_query_with_context(query, user_id, options) do
    financial_context = get_financial_context(user_id)
    user_preferences = Keyword.get(options, :preferences, %{})
    
    %{
      original_query: query,
      financial_context: financial_context,
      user_preferences: user_preferences,
      enhanced_query: query <> " [Context: #{summarize_financial_context(financial_context)}]"
    }
  end

  defp summarize_financial_context(context) do
    case context do
      %{net_worth: net_worth} when not is_nil(net_worth) ->
        "User has net worth of #{Money.to_string(net_worth)}"
      _ ->
        "Limited financial context available"
    end
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, fn
      _k, %{} = v1, %{} = v2 -> deep_merge(v1, v2)
      _k, _v1, v2 -> v2
    end)
  end
end