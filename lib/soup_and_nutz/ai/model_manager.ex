defmodule SoupAndNutz.AI.ModelManager do
  @moduledoc """
  Dynamic model manager that handles multiple AI providers with intelligent
  model selection based on task requirements, user preferences, and performance metrics.
  """

  defstruct [
    :providers,
    :current_models,
    :performance_metrics,
    :selection_strategies,
    :fallback_chain
  ]

  require Logger

  @doc """
  Create a new model manager with provider configurations.
  """
  def new(provider_configs) do
    %__MODULE__{
      providers: provider_configs,
      current_models: %{},
      performance_metrics: initialize_metrics(),
      selection_strategies: load_selection_strategies(),
      fallback_chain: build_fallback_chain(provider_configs)
    }
  end

  @doc """
  Get the default model based on configuration and availability.
  """
  def get_default_model(manager) do
    with {:ok, provider} <- get_preferred_provider(manager),
         {:ok, model} <- get_provider_default_model(manager, provider) do
      {:ok, model}
    else
      {:error, reason} ->
        Logger.warning("Failed to get default model: #{inspect(reason)}")
        fallback_to_available_model(manager)
    end
  end

  @doc """
  Switch to a specific model by name, with automatic provider detection.
  """
  def switch_model(manager, model_name) when is_binary(model_name) do
    case find_model_provider(manager, model_name) do
      {:ok, provider, model_config} ->
        activate_model(manager, provider, model_config)
      {:error, :not_found} ->
        {:error, "Model #{model_name} not found in any provider"}
    end
  end

  @doc """
  Intelligently select the best model for a specific task.
  """
  def select_best_model(manager, task_type, options \\ []) do
    strategy = Keyword.get(options, :strategy, :balanced)
    constraints = Keyword.get(options, :constraints, %{})
    
    candidates = get_suitable_models(manager, task_type, constraints)
    
    case apply_selection_strategy(manager, strategy, candidates, task_type) do
      {:ok, model} -> 
        {:ok, model}
      {:error, reason} -> 
        Logger.warning("Model selection failed: #{inspect(reason)}")
        fallback_to_available_model(manager)
    end
  end

  @doc """
  List all available models across all providers.
  """
  def list_available_models(manager) do
    manager.providers
    |> Enum.flat_map(fn {provider, config} ->
      case check_provider_availability(provider, config) do
        {:ok, models} -> 
          Enum.map(models, fn model -> 
            %{
              name: model,
              provider: provider,
              status: :available,
              capabilities: get_model_capabilities(provider, model)
            }
          end)
        {:error, _reason} -> 
          []
      end
    end)
  end

  @doc """
  Get real-time availability status for all providers.
  """
  def check_providers_health(manager) do
    manager.providers
    |> Enum.map(fn {provider, config} ->
      {provider, check_provider_health(provider, config)}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Update performance metrics for a model based on usage.
  """
  def update_performance_metrics(manager, model_name, metrics) do
    updated_metrics = Map.update(
      manager.performance_metrics,
      model_name,
      metrics,
      &merge_metrics(&1, metrics)
    )
    
    %{manager | performance_metrics: updated_metrics}
  end

  # Private Functions

  defp initialize_metrics() do
    %{
      # Model performance tracking
      default: %{
        response_time: 0.0,
        quality_score: 0.0,
        success_rate: 1.0,
        usage_count: 0,
        last_used: nil
      }
    }
  end

  defp load_selection_strategies() do
    %{
      fastest: %{
        priority: [:response_time, :availability],
        weight: %{response_time: 0.7, quality_score: 0.2, success_rate: 0.1}
      },
      highest_quality: %{
        priority: [:quality_score, :capability_match],
        weight: %{quality_score: 0.7, capability_match: 0.2, response_time: 0.1}
      },
      balanced: %{
        priority: [:success_rate, :quality_score, :response_time],
        weight: %{success_rate: 0.4, quality_score: 0.3, response_time: 0.3}
      },
      cost_effective: %{
        priority: [:cost, :success_rate],
        weight: %{cost: 0.6, success_rate: 0.4}
      }
    }
  end

  defp build_fallback_chain(provider_configs) do
    # Order providers by reliability and availability
    provider_configs
    |> Map.keys()
    |> Enum.sort_by(&get_provider_priority/1)
  end

  defp get_provider_priority(:ollama), do: 1  # Local, most reliable
  defp get_provider_priority(:openai), do: 2  # Commercial, reliable
  defp get_provider_priority(:anthropic), do: 3  # Commercial, reliable
  defp get_provider_priority(_), do: 4  # Others

  defp get_preferred_provider(manager) do
    case manager.providers do
      %{ollama: _config} -> {:ok, :ollama}
      %{openai: config} when not is_nil(config.api_key) -> {:ok, :openai}
      %{anthropic: config} when not is_nil(config.api_key) -> {:ok, :anthropic}
      _ -> {:error, "No available providers"}
    end
  end

  defp get_provider_default_model(manager, provider) do
    case manager.providers[provider] do
      %{default_model: model} = config ->
        model_config = %{
          name: model,
          provider: provider,
          config: config,
          capabilities: get_model_capabilities(provider, model)
        }
        {:ok, model_config}
      _ ->
        {:error, "No default model configured for #{provider}"}
    end
  end

  defp find_model_provider(manager, model_name) do
    result = 
      manager.providers
      |> Enum.find_value(fn {provider, config} ->
        if model_name in (config.available_models || []) do
          model_config = %{
            name: model_name,
            provider: provider,
            config: config,
            capabilities: get_model_capabilities(provider, model_name)
          }
          {provider, model_config}
        end
      end)

    case result do
      {provider, model_config} -> {:ok, provider, model_config}
      nil -> {:error, :not_found}
    end
  end

  defp activate_model(manager, provider, model_config) do
    case check_model_availability(provider, model_config) do
      :ok ->
        updated_manager = %{manager | current_models: Map.put(manager.current_models, provider, model_config)}
        {:ok, model_config}
      {:error, reason} ->
        {:error, "Failed to activate model: #{reason}"}
    end
  end

  defp check_provider_availability(:ollama, config) do
    case make_ollama_request(config.base_url, "/api/tags") do
      {:ok, %{"models" => models}} ->
        model_names = Enum.map(models, & &1["name"])
        {:ok, model_names}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_provider_availability(:openai, config) do
    if config.api_key do
      {:ok, config.available_models || []}
    else
      {:error, "No API key configured"}
    end
  end

  defp check_provider_availability(:anthropic, config) do
    if config.api_key do
      {:ok, config.available_models || []}
    else
      {:error, "No API key configured"}
    end
  end

  defp check_provider_availability(_, _), do: {:error, "Unknown provider"}

  defp check_provider_health(:ollama, config) do
    case make_ollama_request(config.base_url, "/api/version") do
      {:ok, _response} -> :healthy
      {:error, _reason} -> :unhealthy
    end
  end

  defp check_provider_health(:openai, config) do
    if config.api_key, do: :healthy, else: :unhealthy
  end

  defp check_provider_health(:anthropic, config) do
    if config.api_key, do: :healthy, else: :unhealthy
  end

  defp check_model_availability(:ollama, model_config) do
    case make_ollama_request(model_config.config.base_url, "/api/show", %{name: model_config.name}) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_model_availability(:openai, _model_config), do: :ok
  defp check_model_availability(:anthropic, _model_config), do: :ok

  defp get_suitable_models(manager, task_type, constraints) do
    manager.providers
    |> Enum.flat_map(fn {provider, config} ->
      config.available_models
      |> Enum.filter(&model_suitable_for_task?(&1, task_type, constraints))
      |> Enum.map(fn model ->
        %{
          name: model,
          provider: provider,
          config: config,
          capabilities: get_model_capabilities(provider, model),
          metrics: Map.get(manager.performance_metrics, model, %{})
        }
      end)
    end)
  end

  defp model_suitable_for_task?(model_name, task_type, constraints) do
    capabilities = get_model_capabilities_by_name(model_name)
    
    # Check task type compatibility
    task_compatible = case task_type do
      :code_generation -> capabilities.coding
      :mathematical_reasoning -> capabilities.math
      :creative_writing -> capabilities.creativity
      :financial_analysis -> capabilities.reasoning && capabilities.math
      _ -> true
    end
    
    # Check constraints
    constraints_met = 
      constraints
      |> Enum.all?(fn
        {:max_context_length, max_length} -> capabilities.context_length >= max_length
        {:requires_function_calling, true} -> capabilities.function_calling
        {:requires_vision, true} -> capabilities.vision
        _ -> true
      end)
    
    task_compatible && constraints_met
  end

  defp apply_selection_strategy(manager, strategy_name, candidates, task_type) do
    strategy = manager.selection_strategies[strategy_name]
    
    if Enum.empty?(candidates) do
      {:error, "No suitable models found for task: #{task_type}"}
    else
      scored_candidates = 
        candidates
        |> Enum.map(&score_model(&1, strategy, task_type))
        |> Enum.sort_by(& &1.score, :desc)
      
      case scored_candidates do
        [best_model | _] -> {:ok, best_model}
        [] -> {:error, "No models passed scoring criteria"}
      end
    end
  end

  defp score_model(model, strategy, task_type) do
    base_score = calculate_base_score(model, strategy.weight)
    task_bonus = calculate_task_compatibility_bonus(model, task_type)
    availability_penalty = calculate_availability_penalty(model)
    
    final_score = base_score + task_bonus - availability_penalty
    
    Map.put(model, :score, final_score)
  end

  defp calculate_base_score(model, weights) do
    metrics = model.metrics
    
    response_time_score = normalize_response_time(metrics[:response_time] || 1.0)
    quality_score = metrics[:quality_score] || 0.5
    success_rate = metrics[:success_rate] || 1.0
    
    (weights[:response_time] || 0) * response_time_score +
    (weights[:quality_score] || 0) * quality_score +
    (weights[:success_rate] || 0) * success_rate
  end

  defp calculate_task_compatibility_bonus(model, task_type) do
    capabilities = model.capabilities
    
    case task_type do
      :financial_analysis when capabilities.reasoning && capabilities.math -> 0.2
      :code_generation when capabilities.coding -> 0.15
      :creative_writing when capabilities.creativity -> 0.1
      _ -> 0.0
    end
  end

  defp calculate_availability_penalty(model) do
    case check_model_availability(model.provider, model) do
      :ok -> 0.0
      {:error, _} -> 0.5  # Heavy penalty for unavailable models
    end
  end

  defp normalize_response_time(time) when time <= 1.0, do: 1.0
  defp normalize_response_time(time) when time <= 3.0, do: 0.8
  defp normalize_response_time(time) when time <= 5.0, do: 0.5
  defp normalize_response_time(_), do: 0.2

  defp fallback_to_available_model(manager) do
    manager.fallback_chain
    |> Enum.find_value(fn provider ->
      case get_provider_default_model(manager, provider) do
        {:ok, model} -> model
        {:error, _} -> nil
      end
    end)
    |> case do
      nil -> {:error, "No available models in any provider"}
      model -> {:ok, model}
    end
  end

  defp get_model_capabilities(provider, model_name) do
    base_capabilities = %{
      reasoning: true,
      creativity: true,
      coding: false,
      math: true,
      vision: false,
      function_calling: false,
      context_length: 4096
    }
    
    # Enhance based on known model capabilities
    case {provider, model_name} do
      {:ollama, "codellama" <> _} ->
        %{base_capabilities | coding: true, context_length: 16384}
      
      {:ollama, "llama3.1" <> _} ->
        %{base_capabilities | reasoning: true, math: true, context_length: 128000}
      
      {:ollama, "mistral" <> _} ->
        %{base_capabilities | reasoning: true, context_length: 32768}
      
      {:openai, "gpt-4" <> _} ->
        %{base_capabilities | 
          reasoning: true, 
          math: true, 
          coding: true, 
          function_calling: true,
          context_length: 128000
        }
      
      {:openai, "gpt-3.5-turbo"} ->
        %{base_capabilities | function_calling: true, context_length: 16385}
      
      {:anthropic, "claude-3-opus" <> _} ->
        %{base_capabilities | 
          reasoning: true, 
          creativity: true, 
          math: true, 
          coding: true,
          context_length: 200000
        }
      
      _ ->
        base_capabilities
    end
  end

  defp get_model_capabilities_by_name(model_name) do
    # This is a simplified version - in practice you'd want to store this in a database
    cond do
      String.contains?(model_name, "codellama") -> 
        %{coding: true, reasoning: true, math: true, creativity: false, vision: false, function_calling: false, context_length: 16384}
      String.contains?(model_name, "llama3.1") -> 
        %{coding: false, reasoning: true, math: true, creativity: true, vision: false, function_calling: false, context_length: 128000}
      String.contains?(model_name, "gpt-4") -> 
        %{coding: true, reasoning: true, math: true, creativity: true, vision: true, function_calling: true, context_length: 128000}
      true -> 
        %{coding: false, reasoning: true, math: true, creativity: true, vision: false, function_calling: false, context_length: 4096}
    end
  end

  defp merge_metrics(existing, new) do
    %{
      response_time: calculate_weighted_average(existing.response_time, new.response_time, existing.usage_count),
      quality_score: calculate_weighted_average(existing.quality_score, new.quality_score, existing.usage_count),
      success_rate: calculate_weighted_average(existing.success_rate, new.success_rate, existing.usage_count),
      usage_count: existing.usage_count + 1,
      last_used: DateTime.utc_now()
    }
  end

  defp calculate_weighted_average(old_value, new_value, count) when count > 0 do
    (old_value * count + new_value) / (count + 1)
  end
  defp calculate_weighted_average(_old_value, new_value, _count), do: new_value

  defp make_ollama_request(base_url, path, body \\ nil) do
    url = base_url <> path
    
    request_options = [
      method: if(body, do: :post, else: :get),
      url: url,
      headers: [{"Content-Type", "application/json"}],
      timeout: 10_000
    ]
    
    request_options = 
      if body do
        Keyword.put(request_options, :json, body)
      else
        request_options
      end
    
    case Req.request(request_options) do
      {:ok, %{status: 200, body: response}} -> {:ok, response}
      {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, "Request failed: #{inspect(error)}"}
  end
end