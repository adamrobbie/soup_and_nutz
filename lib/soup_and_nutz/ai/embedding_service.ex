defmodule SoupAndNutz.AI.EmbeddingService do
  @moduledoc """
  Embedding service for generating vector embeddings from text using multiple providers.
  Supports OpenAI embeddings, local models via Ollama, and other embedding providers.
  """

  require Logger

  defstruct [
    :provider,
    :model,
    :config,
    :cache
  ]

  @default_model "text-embedding-3-small"
  @cache_ttl 3600  # 1 hour

  @doc """
  Create a new embedding service with configuration.
  """
  def new(config \\ %{}) do
    provider = Map.get(config, :provider, :openai)
    model = Map.get(config, :embedding_model, @default_model)
    
    %__MODULE__{
      provider: provider,
      model: model,
      config: build_config(config),
      cache: %{}
    }
  end

  @doc """
  Generate embedding for a single text string.
  """
  def generate_embedding(service, text) when is_binary(text) do
    cache_key = generate_cache_key(text, service.model)
    
    case get_cached_embedding(service, cache_key) do
      {:ok, embedding} ->
        {:ok, embedding}
      :cache_miss ->
        case generate_fresh_embedding(service, text) do
          {:ok, embedding} ->
            cache_embedding(service, cache_key, embedding)
            {:ok, embedding}
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Generate embeddings for multiple texts in batch.
  """
  def generate_embeddings(service, texts) when is_list(texts) do
    {cached_results, uncached_texts} = separate_cached_uncached(service, texts)
    
    case generate_batch_embeddings(service, uncached_texts) do
      {:ok, new_embeddings} ->
        all_embeddings = merge_cached_and_new(cached_results, new_embeddings, texts)
        {:ok, all_embeddings}
      {:error, reason} ->
        Logger.error("Batch embedding generation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate cosine similarity between two embeddings.
  """
  def cosine_similarity(embedding1, embedding2) when is_list(embedding1) and is_list(embedding2) do
    if length(embedding1) == length(embedding2) do
      dot_product = dot_product(embedding1, embedding2)
      magnitude1 = magnitude(embedding1)
      magnitude2 = magnitude(embedding2)
      
      if magnitude1 > 0 and magnitude2 > 0 do
        dot_product / (magnitude1 * magnitude2)
      else
        0.0
      end
    else
      {:error, "Embedding dimensions do not match"}
    end
  end

  @doc """
  Find most similar embeddings from a collection.
  """
  def find_similar(service, query_embedding, embeddings_collection, top_k \\ 5, threshold \\ 0.7) do
    similarities = 
      embeddings_collection
      |> Enum.map(fn {text, embedding} ->
        similarity = cosine_similarity(query_embedding, embedding)
        {text, embedding, similarity}
      end)
      |> Enum.filter(fn {_text, _embedding, similarity} -> similarity >= threshold end)
      |> Enum.sort_by(fn {_text, _embedding, similarity} -> similarity end, :desc)
      |> Enum.take(top_k)
    
    {:ok, similarities}
  end

  @doc """
  Get embedding dimensions for the current model.
  """
  def get_embedding_dimensions(service) do
    case {service.provider, service.model} do
      {:openai, "text-embedding-3-small"} -> 1536
      {:openai, "text-embedding-3-large"} -> 3072
      {:openai, "text-embedding-ada-002"} -> 1536
      {:ollama, _} -> 768  # Default for most Ollama embedding models
      _ -> 1536  # Reasonable default
    end
  end

  @doc """
  Clear the embedding cache.
  """
  def clear_cache(service) do
    %{service | cache: %{}}
  end

  # Private Functions

  defp build_config(config) do
    %{
      openai_api_key: System.get_env("OPENAI_API_KEY") || Map.get(config, :openai_api_key),
      ollama_base_url: System.get_env("OLLAMA_BASE_URL") || Map.get(config, :ollama_base_url, "http://localhost:11434"),
      batch_size: Map.get(config, :batch_size, 100),
      timeout: Map.get(config, :timeout, 30_000),
      retry_attempts: Map.get(config, :retry_attempts, 3)
    }
  end

  defp generate_cache_key(text, model) do
    :crypto.hash(:sha256, "#{model}:#{text}") |> Base.encode64()
  end

  defp get_cached_embedding(service, cache_key) do
    case Map.get(service.cache, cache_key) do
      nil -> 
        :cache_miss
      {embedding, timestamp} ->
        if DateTime.diff(DateTime.utc_now(), timestamp) < @cache_ttl do
          {:ok, embedding}
        else
          :cache_miss
        end
    end
  end

  defp cache_embedding(service, cache_key, embedding) do
    # Update the service cache - in a real implementation, you might want to use ETS or Redis
    updated_cache = Map.put(service.cache, cache_key, {embedding, DateTime.utc_now()})
    %{service | cache: updated_cache}
  end

  defp generate_fresh_embedding(service, text) do
    case service.provider do
      :openai -> generate_openai_embedding(service, text)
      :ollama -> generate_ollama_embedding(service, text)
      _ -> {:error, "Unsupported embedding provider: #{service.provider}"}
    end
  end

  defp generate_openai_embedding(service, text) do
    if service.config.openai_api_key do
      request_body = %{
        input: text,
        model: service.model
      }
      
      case make_openai_request(service.config.openai_api_key, request_body) do
        {:ok, response} ->
          embedding = get_in(response, ["data", Access.at(0), "embedding"])
          {:ok, embedding}
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, "OpenAI API key not configured"}
    end
  end

  defp generate_ollama_embedding(service, text) do
    request_body = %{
      model: service.model,
      prompt: text
    }
    
    case make_ollama_request(service.config.ollama_base_url, "/api/embeddings", request_body) do
      {:ok, response} ->
        embedding = Map.get(response, "embedding")
        {:ok, embedding}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_batch_embeddings(service, texts) when is_list(texts) do
    case service.provider do
      :openai -> generate_openai_batch_embeddings(service, texts)
      :ollama -> generate_ollama_batch_embeddings(service, texts)
      _ -> {:error, "Batch embeddings not supported for provider: #{service.provider}"}
    end
  end

  defp generate_openai_batch_embeddings(service, texts) do
    if service.config.openai_api_key do
      # Split into smaller batches if needed
      batch_size = service.config.batch_size
      
      texts
      |> Enum.chunk_every(batch_size)
      |> Enum.map(fn batch ->
        request_body = %{
          input: batch,
          model: service.model
        }
        
        case make_openai_request(service.config.openai_api_key, request_body) do
          {:ok, response} ->
            embeddings = 
              response["data"]
              |> Enum.sort_by(& &1["index"])
              |> Enum.map(& &1["embedding"])
            {:ok, embeddings}
          {:error, reason} ->
            {:error, reason}
        end
      end)
      |> combine_batch_results()
    else
      {:error, "OpenAI API key not configured"}
    end
  end

  defp generate_ollama_batch_embeddings(service, texts) do
    # Ollama typically doesn't support batch embeddings, so we do them sequentially
    embedding_tasks = 
      texts
      |> Enum.map(fn text ->
        Task.async(fn ->
          generate_ollama_embedding(service, text)
        end)
      end)
    
    results = Task.await_many(embedding_tasks, service.config.timeout)
    
    case Enum.split_with(results, &match?({:ok, _}, &1)) do
      {successes, []} ->
        embeddings = Enum.map(successes, fn {:ok, embedding} -> embedding end)
        {:ok, embeddings}
      {_successes, errors} ->
        {:error, "Some embeddings failed: #{inspect(errors)}"}
    end
  end

  defp make_openai_request(api_key, request_body) do
    url = "https://api.openai.com/v1/embeddings"
    
    request_options = [
      method: :post,
      url: url,
      headers: [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ],
      json: request_body,
      timeout: 30_000
    ]
    
    case Req.request(request_options) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response}
      {:ok, %{status: status, body: body}} ->
        {:error, "OpenAI API error #{status}: #{inspect(body)}"}
      {:error, reason} ->
        {:error, "OpenAI API request failed: #{inspect(reason)}"}
    end
  rescue
    error ->
      Logger.error("OpenAI embedding request error: #{inspect(error)}")
      {:error, "Request failed"}
  end

  defp make_ollama_request(base_url, path, request_body) do
    url = base_url <> path
    
    request_options = [
      method: :post,
      url: url,
      headers: [{"Content-Type", "application/json"}],
      json: request_body,
      timeout: 30_000
    ]
    
    case Req.request(request_options) do
      {:ok, %{status: 200, body: response}} ->
        {:ok, response}
      {:ok, %{status: status, body: body}} ->
        {:error, "Ollama API error #{status}: #{inspect(body)}"}
      {:error, reason} ->
        {:error, "Ollama API request failed: #{inspect(reason)}"}
    end
  rescue
    error ->
      Logger.error("Ollama embedding request error: #{inspect(error)}")
      {:error, "Request failed"}
  end

  defp separate_cached_uncached(service, texts) do
    {cached, uncached} = 
      texts
      |> Enum.with_index()
      |> Enum.reduce({%{}, []}, fn {text, index}, {cached_acc, uncached_acc} ->
        cache_key = generate_cache_key(text, service.model)
        
        case get_cached_embedding(service, cache_key) do
          {:ok, embedding} ->
            {Map.put(cached_acc, index, embedding), uncached_acc}
          :cache_miss ->
            {cached_acc, [{text, index} | uncached_acc]}
        end
      end)
    
    {cached, Enum.reverse(uncached)}
  end

  defp merge_cached_and_new(cached_results, new_embeddings, original_texts) do
    original_texts
    |> Enum.with_index()
    |> Enum.map(fn {_text, index} ->
      case Map.get(cached_results, index) do
        nil -> 
          # Find the corresponding new embedding
          # This is a simplified approach - in production, you'd need better indexing
          Enum.at(new_embeddings, index - map_size(cached_results))
        cached_embedding -> 
          cached_embedding
      end
    end)
  end

  defp combine_batch_results(batch_results) do
    case Enum.split_with(batch_results, &match?({:ok, _}, &1)) do
      {successes, []} ->
        all_embeddings = 
          successes
          |> Enum.map(fn {:ok, embeddings} -> embeddings end)
          |> List.flatten()
        {:ok, all_embeddings}
      {_successes, errors} ->
        {:error, "Some batches failed: #{inspect(errors)}"}
    end
  end

  # Vector math functions
  defp dot_product(vec1, vec2) do
    vec1
    |> Enum.zip(vec2)
    |> Enum.map(fn {a, b} -> a * b end)
    |> Enum.sum()
  end

  defp magnitude(vector) do
    vector
    |> Enum.map(&(&1 * &1))
    |> Enum.sum()
    |> :math.sqrt()
  end
end