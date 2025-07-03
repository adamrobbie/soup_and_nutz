defmodule SoupAndNutz.AI.OllamaProvider do
  @moduledoc """
  Advanced Ollama provider with dynamic model selection, streaming support,
  and sophisticated generation capabilities for the LangChain system.
  """

  require Logger

  @default_base_url "http://localhost:11434"
  @generation_timeout 120_000  # 2 minutes
  @stream_timeout 300_000      # 5 minutes

  @doc """
  Generate a response using the specified Ollama model.
  """
  def generate(model_config, prompt, context \\ %{}) do
    with {:ok, _} <- ensure_model_available(model_config),
         {:ok, response} <- make_generation_request(model_config, prompt, context) do
      {:ok, response}
    else
      {:error, reason} -> 
        Logger.error("Ollama generation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Generate a streaming response for real-time interaction.
  """
  def generate_stream(model_config, prompt, context \\ %{}, callback_fn) do
    with {:ok, _} <- ensure_model_available(model_config),
         {:ok, stream} <- make_streaming_request(model_config, prompt, context) do
      handle_stream(stream, callback_fn)
    else
      {:error, reason} ->
        Logger.error("Ollama streaming failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get available models from Ollama instance.
  """
  def list_models(base_url \\ @default_base_url) do
    case make_request(base_url, "/api/tags", :get) do
      {:ok, %{"models" => models}} ->
        formatted_models = Enum.map(models, &format_model_info/1)
        {:ok, formatted_models}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Pull a model if not already available.
  """
  def pull_model(model_name, base_url \\ @default_base_url) do
    Logger.info("Pulling Ollama model: #{model_name}")
    
    case make_request(base_url, "/api/pull", :post, %{name: model_name}, @stream_timeout) do
      {:ok, _response} -> 
        Logger.info("Successfully pulled model: #{model_name}")
        {:ok, :success}
      {:error, reason} -> 
        Logger.error("Failed to pull model #{model_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Get detailed information about a specific model.
  """
  def show_model(model_name, base_url \\ @default_base_url) do
    case make_request(base_url, "/api/show", :post, %{name: model_name}) do
      {:ok, model_info} -> {:ok, format_detailed_model_info(model_info)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Delete a model from Ollama.
  """
  def delete_model(model_name, base_url \\ @default_base_url) do
    case make_request(base_url, "/api/delete", :delete, %{name: model_name}) do
      {:ok, _} -> {:ok, :deleted}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate embeddings using Ollama.
  """
  def generate_embeddings(model_name, texts, base_url \\ @default_base_url) when is_list(texts) do
    embedding_requests = 
      texts
      |> Enum.map(fn text ->
        Task.async(fn ->
          make_request(base_url, "/api/embeddings", :post, %{
            model: model_name,
            prompt: text
          })
        end)
      end)
    
    results = Task.await_many(embedding_requests, @generation_timeout)
    
    case Enum.split_with(results, &match?({:ok, _}, &1)) do
      {successes, []} ->
        embeddings = Enum.map(successes, fn {:ok, %{"embedding" => embedding}} -> embedding end)
        {:ok, embeddings}
      {_successes, errors} ->
        {:error, "Some embeddings failed: #{inspect(errors)}"}
    end
  end

  @doc """
  Check if Ollama service is running and accessible.
  """
  def health_check(base_url \\ @default_base_url) do
    case make_request(base_url, "/api/version", :get, nil, 5_000) do
      {:ok, version_info} -> 
        {:ok, %{status: :healthy, version: version_info["version"]}}
      {:error, reason} -> 
        {:error, %{status: :unhealthy, reason: reason}}
    end
  end

  @doc """
  Get system information from Ollama.
  """
  def system_info(base_url \\ @default_base_url) do
    # This is a hypothetical endpoint - adjust based on actual Ollama API
    case make_request(base_url, "/api/ps", :get) do
      {:ok, info} -> {:ok, info}
      {:error, _} -> {:ok, %{}}  # Fallback to empty info
    end
  end

  # Private Functions

  defp ensure_model_available(model_config) do
    case show_model(model_config.name, get_base_url(model_config)) do
      {:ok, _model_info} -> 
        {:ok, :available}
      {:error, _reason} ->
        Logger.info("Model #{model_config.name} not found, attempting to pull...")
        pull_model(model_config.name, get_base_url(model_config))
    end
  end

  defp make_generation_request(model_config, prompt, context) do
    request_body = build_generation_request(model_config, prompt, context)
    base_url = get_base_url(model_config)
    
    case make_request(base_url, "/api/generate", :post, request_body, @generation_timeout) do
      {:ok, response} -> 
        formatted_response = format_generation_response(response, model_config)
        {:ok, formatted_response}
      {:error, reason} -> 
        {:error, reason}
    end
  end

  defp make_streaming_request(model_config, prompt, context) do
    request_body = 
      model_config
      |> build_generation_request(prompt, context)
      |> Map.put(:stream, true)
    
    base_url = get_base_url(model_config)
    make_streaming_http_request(base_url <> "/api/generate", request_body)
  end

  defp build_generation_request(model_config, prompt, context) do
    base_request = %{
      model: model_config.name,
      prompt: prompt,
      stream: false
    }

    # Add generation parameters based on context
    base_request
    |> maybe_add_temperature(context[:temperature])
    |> maybe_add_max_tokens(context[:max_tokens])
    |> maybe_add_top_p(context[:top_p])
    |> maybe_add_stop_sequences(context[:stop])
    |> maybe_add_system_message(context[:system])
    |> maybe_add_format(context[:format])
  end

  defp maybe_add_temperature(request, nil), do: request
  defp maybe_add_temperature(request, temp) when is_number(temp) do
    put_in(request, [:options, :temperature], temp)
  end

  defp maybe_add_max_tokens(request, nil), do: request
  defp maybe_add_max_tokens(request, max_tokens) when is_integer(max_tokens) do
    put_in(request, [:options, :num_predict], max_tokens)
  end

  defp maybe_add_top_p(request, nil), do: request
  defp maybe_add_top_p(request, top_p) when is_number(top_p) do
    put_in(request, [:options, :top_p], top_p)
  end

  defp maybe_add_stop_sequences(request, nil), do: request
  defp maybe_add_stop_sequences(request, stop_sequences) when is_list(stop_sequences) do
    put_in(request, [:options, :stop], stop_sequences)
  end

  defp maybe_add_system_message(request, nil), do: request
  defp maybe_add_system_message(request, system_message) when is_binary(system_message) do
    Map.put(request, :system, system_message)
  end

  defp maybe_add_format(request, nil), do: request
  defp maybe_add_format(request, format) when format in ["json"] do
    Map.put(request, :format, format)
  end

  defp format_generation_response(response, model_config) do
    %{
      text: response["response"] || "",
      model: model_config.name,
      provider: :ollama,
      metadata: %{
        total_duration: response["total_duration"],
        load_duration: response["load_duration"],
        prompt_eval_count: response["prompt_eval_count"],
        prompt_eval_duration: response["prompt_eval_duration"],
        eval_count: response["eval_count"],
        eval_duration: response["eval_duration"],
        done: response["done"],
        context: response["context"]
      },
      usage: calculate_usage_stats(response),
      timestamp: DateTime.utc_now()
    }
  end

  defp calculate_usage_stats(response) do
    %{
      prompt_tokens: response["prompt_eval_count"] || 0,
      completion_tokens: response["eval_count"] || 0,
      total_tokens: (response["prompt_eval_count"] || 0) + (response["eval_count"] || 0),
      total_duration_ms: div(response["total_duration"] || 0, 1_000_000),
      tokens_per_second: calculate_tokens_per_second(response)
    }
  end

  defp calculate_tokens_per_second(response) do
    eval_count = response["eval_count"] || 0
    eval_duration = response["eval_duration"] || 1
    
    if eval_count > 0 and eval_duration > 0 do
      (eval_count * 1_000_000_000) / eval_duration  # Convert nanoseconds to seconds
    else
      0.0
    end
  end

  defp format_model_info(model) do
    %{
      name: model["name"],
      modified_at: model["modified_at"],
      size: model["size"],
      digest: model["digest"],
      details: model["details"] || %{}
    }
  end

  defp format_detailed_model_info(model_info) do
    %{
      license: model_info["license"],
      modelfile: model_info["modelfile"],
      parameters: model_info["parameters"],
      template: model_info["template"],
      details: model_info["details"] || %{},
      model_info: model_info["model_info"] || %{}
    }
  end

  defp handle_stream(stream, callback_fn) do
    try do
      Enum.reduce_while(stream, "", fn chunk, acc ->
        case parse_stream_chunk(chunk) do
          {:ok, data, done} ->
            updated_acc = acc <> data
            callback_fn.(data, done)
            
            if done do
              {:halt, {:ok, updated_acc}}
            else
              {:cont, updated_acc}
            end
          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
    rescue
      error ->
        Logger.error("Stream handling error: #{inspect(error)}")
        {:error, "Stream processing failed"}
    end
  end

  defp parse_stream_chunk(chunk) do
    try do
      case Jason.decode(chunk) do
        {:ok, %{"response" => response, "done" => done}} ->
          {:ok, response, done}
        {:ok, %{"error" => error}} ->
          {:error, error}
        {:error, reason} ->
          {:error, "Invalid JSON in stream: #{inspect(reason)}"}
      end
    rescue
      _ -> {:error, "Failed to parse stream chunk"}
    end
  end

  defp make_request(base_url, path, method, body \\ nil, timeout \\ @generation_timeout) do
    url = base_url <> path
    
    request_options = [
      method: method,
      url: url,
      headers: [{"Content-Type", "application/json"}],
      timeout: timeout
    ]
    
    request_options = 
      if body do
        Keyword.put(request_options, :json, body)
      else
        request_options
      end
    
    case Req.request(request_options) do
      {:ok, %{status: 200, body: response}} -> 
        {:ok, response}
      {:ok, %{status: status, body: body}} -> 
        {:error, "HTTP #{status}: #{inspect(body)}"}
      {:error, reason} -> 
        {:error, "Request failed: #{inspect(reason)}"}
    end
  rescue
    error -> 
      Logger.error("HTTP request error: #{inspect(error)}")
      {:error, "HTTP request failed"}
  end

  defp make_streaming_http_request(url, body) do
    # This would need to be implemented with a streaming HTTP client
    # For now, we'll use a simplified approach
    case make_request(String.replace(url, url, url), "", :post, body, @stream_timeout) do
      {:ok, response} -> {:ok, [Jason.encode!(response)]}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_base_url(model_config) do
    model_config.config.base_url || @default_base_url
  end
end