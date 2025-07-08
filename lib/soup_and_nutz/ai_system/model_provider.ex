defmodule SoupAndNutz.AISystem.ModelProvider do
  @moduledoc """
  Advanced model provider for managing multiple LLM backends with user preferences.

  Supports:
  - OpenAI API (GPT-4, GPT-3.5-turbo, etc.)
  - Anthropic API (Claude models)
  - Ollama (local models)
  - Custom local models
  - User-specific model preferences
  - Dynamic model switching
  """

  use GenServer
  require Logger

  alias LangChain.ChatModels.{ChatOpenAI, ChatAnthropic, ChatOllamaAI}
  alias SoupAndNutz.Repo
  alias SoupAndNutz.Accounts.{User, UserModelPreference}

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get the current model for a user or the default model.
  """
  def get_model(user_id \\ nil) do
    GenServer.call(__MODULE__, {:get_model, user_id})
  end

  @doc """
  Set the preferred model for a user.
  """
  def set_user_model(user_id, model_config) do
    GenServer.call(__MODULE__, {:set_user_model, user_id, model_config})
  end

  @doc """
  Get available models.
  """
  def get_available_models do
    GenServer.call(__MODULE__, :get_available_models)
  end

  @doc """
  Test a model configuration.
  """
  def test_model(config) do
    GenServer.call(__MODULE__, {:test_model, config})
  end

  @doc """
  Get model statistics and usage.
  """
  def get_model_stats do
    GenServer.call(__MODULE__, :get_model_stats)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Load default configuration
    default_config = load_default_config()

    # Initialize state
    state = %{
      default_model: default_config,
      user_models: %{},
      available_models: get_available_models_config(),
      model_stats: %{},
      health_checks: %{}
    }

    # Start periodic health checks
    schedule_health_check()

    {:ok, state}
  end

  @impl true
  def handle_call({:get_model, user_id}, _from, state) do
    model_config = get_user_model_config(state, user_id)

    case create_langchain_model(model_config) do
      {:ok, model} ->
        {:reply, {:ok, model}, state}
      {:error, reason} ->
        Logger.error("Failed to create model: #{inspect(reason)}")
        # Fallback to default model
        case create_langchain_model(state.default_model) do
          {:ok, fallback_model} ->
            {:reply, {:ok, fallback_model}, state}
          {:error, fallback_reason} ->
            {:reply, {:error, "All models failed: #{inspect(fallback_reason)}"}, state}
        end
    end
  end

  @impl true
  def handle_call({:set_user_model, user_id, model_config}, _from, state) do
    case validate_model_config(model_config) do
      {:ok, validated_config} ->
        # Store user preference in database
        store_user_model_preference(user_id, validated_config)

        # Update in-memory state
        new_state = Map.update!(state, :user_models, fn user_models ->
          Map.put(user_models, user_id, validated_config)
        end)

        {:reply, {:ok, validated_config}, new_state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_available_models, _from, state) do
    {:reply, state.available_models, state}
  end

  @impl true
  def handle_call({:test_model, config}, _from, state) do
    case create_langchain_model(config) do
      {:ok, model} ->
        # Test with a simple prompt
        test_result = test_model_with_prompt(model)
        {:reply, {:ok, test_result}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_model_stats, _from, state) do
    {:reply, state.model_stats, state}
  end

  @impl true
  def handle_info(:health_check, state) do
    new_state = perform_health_checks(state)
    schedule_health_check()
    {:noreply, new_state}
  end

  # Private Functions

  defp get_user_model_config(state, user_id) when is_binary(user_id) do
    # First check in-memory cache
    case Map.get(state.user_models, user_id) do
      nil ->
        # Load from database
        case load_user_model_preference(user_id) do
          {:ok, config} ->
            # Update cache
            GenServer.cast(__MODULE__, {:cache_user_model, user_id, config})
            config
          {:error, _} ->
            state.default_model
        end
      config ->
        config
    end
  end

  defp get_user_model_config(state, _), do: state.default_model

  defp create_langchain_model(config) do
    try do
      model = case config.provider do
        :openai -> create_openai_model(config)
        :anthropic -> create_anthropic_model(config)
        :ollama -> create_ollama_model(config)
        :local -> create_local_model(config)
        _ -> raise "Unsupported provider: #{config.provider}"
      end
      {:ok, model}
    rescue
      e ->
        Logger.error("Failed to create model: #{inspect(e)}")
        {:error, "Model creation failed: #{inspect(e)}"}
    end
  end

  defp create_openai_model(config) do
    api_key = config.api_key || System.get_env("OPENAI_API_KEY")

    if is_nil(api_key) do
      raise "OpenAI API key not found"
    end

    ChatOpenAI.new!(%{
      model: config.model,
      api_key: api_key,
      temperature: config.temperature || 0.7,
      max_tokens: config.max_tokens,
      base_url: config.base_url,
      receive_timeout: config.timeout || 60_000
    })
  end

  defp create_anthropic_model(config) do
    api_key = config.api_key || System.get_env("ANTHROPIC_API_KEY")

    if is_nil(api_key) do
      raise "Anthropic API key not found"
    end

    ChatAnthropic.new!(%{
      model: config.model,
      api_key: api_key,
      temperature: config.temperature || 0.7,
      max_tokens: config.max_tokens,
      receive_timeout: config.timeout || 60_000
    })
  end

  defp create_ollama_model(config) do
    base_url = config.base_url || "http://localhost:11434"

    ChatOllamaAI.new!(%{
      model: config.model,
      base_url: base_url,
      temperature: config.temperature || 0.7,
      receive_timeout: config.timeout || 60_000
    })
  end

  defp create_local_model(config) do
    # For OpenAI-compatible local models
    ChatOpenAI.new!(%{
      model: config.model,
      api_key: config.api_key || "dummy-key",
      base_url: config.base_url,
      temperature: config.temperature || 0.7,
      max_tokens: config.max_tokens,
      receive_timeout: config.timeout || 60_000
    })
  end

  defp validate_model_config(config) do
    required_fields = [:provider, :model]

    case Enum.find(required_fields, fn field ->
      not Map.has_key?(config, field) or is_nil(config[field])
    end) do
      nil ->
        # Validate provider-specific requirements
        validate_provider_config(config)
      field ->
        {:error, "Missing required field: #{field}"}
    end
  end

  defp validate_provider_config(%{provider: :openai} = config) do
    api_key = config.api_key || System.get_env("OPENAI_API_KEY")
    if is_nil(api_key) do
      {:error, "OpenAI API key required"}
    else
      {:ok, config}
    end
  end

  defp validate_provider_config(%{provider: :anthropic} = config) do
    api_key = config.api_key || System.get_env("ANTHROPIC_API_KEY")
    if is_nil(api_key) do
      {:error, "Anthropic API key required"}
    else
      {:ok, config}
    end
  end

  defp validate_provider_config(%{provider: :ollama} = config) do
    # For Ollama, we just need the model name
    {:ok, config}
  end

  defp validate_provider_config(%{provider: :local} = config) do
    # For local models, we need base_url
    if is_nil(config.base_url) do
      {:error, "Base URL required for local models"}
    else
      {:ok, config}
    end
  end

  defp validate_provider_config(config) do
    {:error, "Unsupported provider: #{config.provider}"}
  end

  defp test_model_with_prompt(model) do
    try do
      # Simple test prompt
      test_prompt = "Hello, this is a test. Please respond with 'OK' if you can see this message."

      # Create a simple message
      message = LangChain.Message.new_user!(test_prompt)

      # Test the model
      case LangChain.ChatModels.ChatModel.call(model, message) do
        {:ok, response} ->
          %{
            status: "success",
            response: response.content,
            model: model.__struct__,
            timestamp: DateTime.utc_now()
          }
        {:error, reason} ->
          %{
            status: "error",
            error: inspect(reason),
            model: model.__struct__,
            timestamp: DateTime.utc_now()
          }
      end
    rescue
      e ->
        %{
          status: "error",
          error: inspect(e),
          model: model.__struct__,
          timestamp: DateTime.utc_now()
        }
    end
  end

  defp load_default_config do
    # Load from environment or use a sensible default
    provider = String.to_atom(System.get_env("DEFAULT_MODEL_PROVIDER") || "openai")
    model = System.get_env("DEFAULT_MODEL") || "gpt-3.5-turbo"

    %{
      provider: provider,
      model: model,
      temperature: 0.7,
      timeout: 60_000
    }
  end

  defp get_available_models_config do
    [
      # OpenAI models
      %{
        name: "GPT-4",
        provider: :openai,
        model: "gpt-4",
        description: "OpenAI's most capable model",
        category: "premium"
      },
      %{
        name: "GPT-4 Turbo",
        provider: :openai,
        model: "gpt-4-turbo-preview",
        description: "OpenAI's latest GPT-4 model",
        category: "premium"
      },
      %{
        name: "GPT-3.5 Turbo",
        provider: :openai,
        model: "gpt-3.5-turbo",
        description: "OpenAI's fast and efficient model",
        category: "standard"
      },
      # Anthropic models
      %{
        name: "Claude 3 Opus",
        provider: :anthropic,
        model: "claude-3-opus-20240229",
        description: "Anthropic's most powerful model",
        category: "premium"
      },
      %{
        name: "Claude 3 Sonnet",
        provider: :anthropic,
        model: "claude-3-sonnet-20240229",
        description: "Anthropic's balanced model",
        category: "standard"
      },
      %{
        name: "Claude 3 Haiku",
        provider: :anthropic,
        model: "claude-3-haiku-20240307",
        description: "Anthropic's fastest model",
        category: "standard"
      },
      # Ollama models
      %{
        name: "Llama 2 (7B)",
        provider: :ollama,
        model: "llama2",
        description: "Meta's Llama 2 model (7B parameters)",
        category: "local"
      },
      %{
        name: "Llama 2 (13B)",
        provider: :ollama,
        model: "llama2:13b",
        description: "Meta's Llama 2 model (13B parameters)",
        category: "local"
      },
      %{
        name: "Mistral (7B)",
        provider: :ollama,
        model: "mistral",
        description: "Mistral AI's 7B model",
        category: "local"
      },
      %{
        name: "Code Llama",
        provider: :ollama,
        model: "codellama",
        description: "Code-focused Llama model",
        category: "local"
      },
      %{
        name: "Phi-2",
        provider: :ollama,
        model: "phi",
        description: "Microsoft's Phi-2 model",
        category: "local"
      },
      %{
        name: "Gemma (2B)",
        provider: :ollama,
        model: "gemma:2b",
        description: "Google's Gemma 2B model",
        category: "local"
      },
      %{
        name: "Gemma (7B)",
        provider: :ollama,
        model: "gemma:7b",
        description: "Google's Gemma 7B model",
        category: "local"
      }
    ]
  end

    defp store_user_model_preference(user_id, config) do
    case UserModelPreference.create_or_update_active(user_id, config) do
      {:ok, preference} ->
        Logger.info("Stored model preference for user #{user_id}: #{inspect(config)}")
        {:ok, preference}
      {:error, changeset} ->
        Logger.error("Failed to store model preference: #{inspect(changeset.errors)}")
        {:error, "Failed to store model preference"}
    end
  end

  defp load_user_model_preference(user_id) do
    case UserModelPreference.get_active_by_user_id(user_id) do
      nil ->
        Logger.info("No model preference found for user #{user_id}, using default")
        {:error, :not_found}
      preference ->
        Logger.info("Loaded model preference for user #{user_id}: #{inspect(preference.model_config)}")
        {:ok, preference.model_config}
    end
  end

  defp perform_health_checks(state) do
    # Check health of available models
    health_results = Enum.map(state.available_models, fn model_config ->
      case create_langchain_model(model_config) do
        {:ok, model} ->
          test_result = test_model_with_prompt(model)
          {model_config.model, test_result.status == "success"}
        {:error, _} ->
          {model_config.model, false}
      end
    end)

    health_map = Map.new(health_results)

    Map.put(state, :health_checks, health_map)
  end

  defp schedule_health_check do
    # Check every 5 minutes
    Process.send_after(self(), :health_check, 5 * 60 * 1000)
  end
end
