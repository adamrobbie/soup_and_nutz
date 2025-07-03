defmodule SoupAndNutz.AI.RAGChain do
  @moduledoc """
  Retrieval Augmented Generation (RAG) chain providing sophisticated document retrieval,
  chunking, embedding, and context-aware generation for financial applications.
  """

  defstruct [
    :vector_store,
    :embedding_service,
    :document_processor,
    :retrieval_config,
    :cache
  ]

  require Logger
  alias SoupAndNutz.AI.EmbeddingService
  alias SoupAndNutz.Repo

  @default_chunk_size 1000
  @default_chunk_overlap 200
  @default_top_k 5
  @cache_ttl 3600  # 1 hour in seconds

  @doc """
  Create a new RAG chain with configuration.
  """
  def new(config \\ %{}) do
    %__MODULE__{
      embedding_service: EmbeddingService.new(config),
      document_processor: initialize_document_processor(),
      retrieval_config: build_retrieval_config(config),
      vector_store: initialize_vector_store(),
      cache: %{}
    }
  end

  @doc """
  Add documents to the RAG knowledge base with automatic chunking and embedding.
  """
  def add_documents(rag_chain, documents, metadata \\ %{}) when is_list(documents) do
    try do
      processed_docs = 
        documents
        |> Enum.map(&process_document(&1, metadata))
        |> List.flatten()
      
      embedded_docs = embed_document_chunks(rag_chain, processed_docs)
      stored_docs = store_embeddings(rag_chain, embedded_docs)
      
      Logger.info("Successfully added #{length(stored_docs)} document chunks to RAG knowledge base")
      {:ok, stored_docs}
    rescue
      error ->
        Logger.error("Failed to add documents to RAG: #{inspect(error)}")
        {:error, "Document addition failed"}
    end
  end

  @doc """
  Execute a RAG query with context-aware retrieval and generation.
  """
  def query(rag_chain, enhanced_query, model) do
    query_text = extract_query_text(enhanced_query)
    
    with {:ok, relevant_docs} <- retrieve_relevant_documents(rag_chain, query_text),
         {:ok, context} <- build_generation_context(enhanced_query, relevant_docs),
         {:ok, response} <- generate_response(model, context) do
      
      formatted_response = format_rag_response(response, relevant_docs, query_text)
      {:ok, formatted_response}
    else
      {:error, reason} ->
        Logger.error("RAG query failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Perform semantic search within the knowledge base.
  """
  def semantic_search(rag_chain, query, options \\ []) do
    top_k = Keyword.get(options, :top_k, @default_top_k)
    threshold = Keyword.get(options, :threshold, 0.7)
    filters = Keyword.get(options, :filters, %{})
    
    with {:ok, query_embedding} <- get_query_embedding(rag_chain, query),
         {:ok, results} <- vector_search(rag_chain, query_embedding, top_k, threshold, filters) do
      {:ok, results}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Update the RAG knowledge base with new financial data.
  """
  def update_financial_context(rag_chain, user_id) do
    financial_documents = generate_financial_documents(user_id)
    add_documents(rag_chain, financial_documents, %{user_id: user_id, type: :financial_data})
  end

  @doc """
  Clear old cached embeddings and refresh knowledge base.
  """
  def refresh_knowledge_base(rag_chain, max_age_days \\ 30) do
    cutoff_date = DateTime.add(DateTime.utc_now(), -max_age_days * 24 * 3600, :second)
    
    # This would typically interact with a vector database
    Logger.info("Refreshing knowledge base, removing entries older than #{max_age_days} days")
    {:ok, :refreshed}
  end

  # Private Functions

  defp initialize_document_processor() do
    %{
      supported_formats: [:text, :markdown, :json, :csv],
      chunk_size: @default_chunk_size,
      chunk_overlap: @default_chunk_overlap,
      processors: load_document_processors()
    }
  end

  defp build_retrieval_config(config) do
    %{
      chunk_size: Map.get(config, :chunk_size, @default_chunk_size),
      chunk_overlap: Map.get(config, :chunk_overlap, @default_chunk_overlap),
      top_k: Map.get(config, :top_k, @default_top_k),
      embedding_model: Map.get(config, :embedding_model, "text-embedding-3-small"),
      similarity_threshold: Map.get(config, :similarity_threshold, 0.7),
      max_context_length: Map.get(config, :max_context_length, 4000)
    }
  end

  defp initialize_vector_store() do
    # In a real implementation, this would connect to a vector database like Pinecone, Weaviate, or pgvector
    %{
      type: :pgvector,
      connection: Repo,
      collection_name: "financial_knowledge_base"
    }
  end

  defp load_document_processors() do
    %{
      text: &process_text_document/1,
      markdown: &process_markdown_document/1,
      json: &process_json_document/1,
      csv: &process_csv_document/1
    }
  end

  defp process_document(document, metadata) do
    format = detect_document_format(document)
    processor = get_document_processor(format)
    
    document
    |> processor.()
    |> chunk_document()
    |> Enum.map(&add_metadata(&1, metadata))
  end

  defp detect_document_format(document) when is_binary(document) do
    cond do
      String.starts_with?(document, "{") or String.starts_with?(document, "[") -> :json
      String.contains?(document, "# ") or String.contains?(document, "## ") -> :markdown
      String.contains?(document, ",") and String.contains?(document, "\n") -> :csv
      true -> :text
    end
  end

  defp get_document_processor(:text), do: &process_text_document/1
  defp get_document_processor(:markdown), do: &process_markdown_document/1
  defp get_document_processor(:json), do: &process_json_document/1
  defp get_document_processor(:csv), do: &process_csv_document/1
  defp get_document_processor(_), do: &process_text_document/1

  defp process_text_document(text) do
    text
    |> String.trim()
    |> clean_text()
  end

  defp process_markdown_document(markdown) do
    # Enhanced markdown processing
    markdown
    |> String.replace(~r/^#+\s+/, "")  # Remove markdown headers
    |> String.replace(~r/\*\*(.*?)\*\*/, "\\1")  # Remove bold formatting
    |> String.replace(~r/\*(.*?)\*/, "\\1")  # Remove italic formatting
    |> clean_text()
  end

  defp process_json_document(json_string) do
    case Jason.decode(json_string) do
      {:ok, data} -> extract_text_from_json(data)
      {:error, _} -> json_string
    end
  end

  defp process_csv_document(csv_string) do
    csv_string
    |> String.split("\n")
    |> Enum.map(&String.replace(&1, ",", " "))
    |> Enum.join(" ")
    |> clean_text()
  end

  defp clean_text(text) do
    text
    |> String.replace(~r/\s+/, " ")  # Normalize whitespace
    |> String.replace(~r/[^\w\s\.\,\!\?\-]/, "")  # Remove special characters
    |> String.trim()
  end

  defp extract_text_from_json(data) when is_map(data) do
    data
    |> Map.values()
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end
  defp extract_text_from_json(data) when is_list(data) do
    data
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end
  defp extract_text_from_json(data) when is_binary(data), do: data
  defp extract_text_from_json(_), do: ""

  defp chunk_document(text) do
    chunk_size = @default_chunk_size
    overlap = @default_chunk_overlap
    
    text
    |> String.graphemes()
    |> Enum.chunk_every(chunk_size, chunk_size - overlap, :discard)
    |> Enum.map(&Enum.join/1)
    |> Enum.filter(&(String.length(&1) > 50))  # Filter out very short chunks
  end

  defp add_metadata(chunk, metadata) do
    %{
      content: chunk,
      metadata: Map.merge(metadata, %{
        chunk_length: String.length(chunk),
        created_at: DateTime.utc_now()
      })
    }
  end

  defp embed_document_chunks(rag_chain, chunks) do
    chunk_texts = Enum.map(chunks, & &1.content)
    
    case EmbeddingService.generate_embeddings(rag_chain.embedding_service, chunk_texts) do
      {:ok, embeddings} ->
        chunks
        |> Enum.zip(embeddings)
        |> Enum.map(fn {chunk, embedding} ->
          Map.put(chunk, :embedding, embedding)
        end)
      {:error, reason} ->
        Logger.error("Failed to generate embeddings: #{inspect(reason)}")
        []
    end
  end

  defp store_embeddings(rag_chain, embedded_chunks) do
    # In a real implementation, this would store in a vector database
    # For now, we'll simulate storage and return the chunks
    embedded_chunks
  end

  defp extract_query_text(enhanced_query) when is_map(enhanced_query) do
    enhanced_query.original_query || enhanced_query.enhanced_query || ""
  end
  defp extract_query_text(query) when is_binary(query), do: query

  defp retrieve_relevant_documents(rag_chain, query) do
    case get_cached_results(rag_chain, query) do
      {:ok, cached_results} ->
        {:ok, cached_results}
      :cache_miss ->
        perform_retrieval(rag_chain, query)
    end
  end

  defp get_cached_results(rag_chain, query) do
    cache_key = :crypto.hash(:sha256, query) |> Base.encode64()
    
    case Map.get(rag_chain.cache, cache_key) do
      nil -> :cache_miss
      {results, timestamp} ->
        if DateTime.diff(DateTime.utc_now(), timestamp) < @cache_ttl do
          {:ok, results}
        else
          :cache_miss
        end
    end
  end

  defp perform_retrieval(rag_chain, query) do
    with {:ok, query_embedding} <- get_query_embedding(rag_chain, query),
         {:ok, similar_docs} <- vector_search(rag_chain, query_embedding) do
      
      # Cache the results
      cache_key = :crypto.hash(:sha256, query) |> Base.encode64()
      updated_cache = Map.put(rag_chain.cache, cache_key, {similar_docs, DateTime.utc_now()})
      
      {:ok, similar_docs}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_query_embedding(rag_chain, query) do
    EmbeddingService.generate_embedding(rag_chain.embedding_service, query)
  end

  defp vector_search(rag_chain, query_embedding, top_k \\ @default_top_k, threshold \\ 0.7, filters \\ %{}) do
    # This is a simplified implementation
    # In production, you'd use a proper vector database query
    
    # For demonstration, return mock relevant documents
    mock_documents = [
      %{
        content: "Investment diversification reduces portfolio risk by spreading investments across different asset classes.",
        metadata: %{source: "investment_guide", score: 0.89},
        similarity_score: 0.89
      },
      %{
        content: "Emergency funds should cover 3-6 months of living expenses and be kept in easily accessible accounts.",
        metadata: %{source: "financial_planning", score: 0.85},
        similarity_score: 0.85
      },
      %{
        content: "Debt avalanche method prioritizes paying off highest interest rate debts first to minimize total interest paid.",
        metadata: %{source: "debt_management", score: 0.82},
        similarity_score: 0.82
      }
    ]
    
    filtered_docs = 
      mock_documents
      |> Enum.filter(&(&1.similarity_score >= threshold))
      |> Enum.take(top_k)
    
    {:ok, filtered_docs}
  end

  defp build_generation_context(enhanced_query, relevant_docs) do
    context = %{
      query: enhanced_query,
      retrieved_documents: relevant_docs,
      document_summary: summarize_documents(relevant_docs),
      user_context: extract_user_context(enhanced_query)
    }
    
    {:ok, context}
  end

  defp summarize_documents(documents) do
    document_texts = Enum.map(documents, & &1.content)
    
    summary = %{
      total_documents: length(documents),
      average_relevance: calculate_average_relevance(documents),
      key_topics: extract_key_topics(document_texts),
      sources: extract_sources(documents)
    }
    
    summary
  end

  defp calculate_average_relevance(documents) do
    if Enum.empty?(documents) do
      0.0
    else
      documents
      |> Enum.map(& &1.similarity_score)
      |> Enum.sum()
      |> Kernel./(length(documents))
    end
  end

  defp extract_key_topics(texts) do
    # Simple keyword extraction - in production you'd use more sophisticated NLP
    texts
    |> Enum.join(" ")
    |> String.downcase()
    |> String.split()
    |> Enum.frequencies()
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(5)
    |> Enum.map(&elem(&1, 0))
  end

  defp extract_sources(documents) do
    documents
    |> Enum.map(& &1.metadata[:source])
    |> Enum.uniq()
    |> Enum.filter(& &1)
  end

  defp extract_user_context(enhanced_query) when is_map(enhanced_query) do
    enhanced_query.financial_context || %{}
  end
  defp extract_user_context(_), do: %{}

  defp generate_response(model, context) do
    # This would interface with the model provider
    SoupAndNutz.AI.OllamaProvider.generate(model, build_rag_prompt(context), %{})
  end

  defp build_rag_prompt(context) do
    """
    Based on the following financial knowledge and the user's question, provide a comprehensive and accurate response.

    Retrieved Knowledge:
    #{format_retrieved_documents(context.retrieved_documents)}

    Document Summary:
    - #{context.document_summary.total_documents} relevant documents found
    - Average relevance: #{Float.round(context.document_summary.average_relevance, 2)}
    - Key topics: #{Enum.join(context.document_summary.key_topics, ", ")}

    User Question: #{extract_query_text(context.query)}

    Please provide a detailed response that:
    1. Directly answers the user's question
    2. References specific information from the retrieved documents
    3. Provides actionable advice when appropriate
    4. Acknowledges any limitations in the available information

    Response:
    """
  end

  defp format_retrieved_documents(documents) do
    documents
    |> Enum.with_index(1)
    |> Enum.map(fn {doc, index} ->
      "#{index}. #{doc.content} (Relevance: #{Float.round(doc.similarity_score, 2)})"
    end)
    |> Enum.join("\n\n")
  end

  defp format_rag_response(response, relevant_docs, original_query) do
    %{
      answer: response.text,
      sources: extract_sources(relevant_docs),
      relevance_scores: Enum.map(relevant_docs, & &1.similarity_score),
      total_sources: length(relevant_docs),
      query: original_query,
      model_used: response.model,
      timestamp: DateTime.utc_now(),
      metadata: %{
        retrieval_method: "vector_similarity",
        average_relevance: calculate_average_relevance(relevant_docs),
        processing_time: response.metadata[:total_duration]
      }
    }
  end

  defp generate_financial_documents(user_id) do
    # Generate synthetic documents based on user's financial data for RAG
    try do
      assets = SoupAndNutz.FinancialInstruments.list_assets_for_user(user_id)
      debts = SoupAndNutz.FinancialInstruments.list_debt_obligations_for_user(user_id)
      goals = SoupAndNutz.FinancialGoals.list_goals_for_user(user_id)
      
      [
        generate_asset_summary(assets),
        generate_debt_summary(debts),
        generate_goals_summary(goals),
        generate_financial_profile(user_id)
      ]
      |> Enum.filter(&(&1 != ""))
    rescue
      _ -> []
    end
  end

  defp generate_asset_summary(assets) do
    if Enum.empty?(assets) do
      ""
    else
      total_value = assets |> Enum.map(& &1.current_value) |> Enum.reduce(Money.new(0), &Money.add/2)
      
      """
      Asset Portfolio Summary:
      Total asset value: #{Money.to_string(total_value)}
      Number of assets: #{length(assets)}
      Asset types: #{assets |> Enum.map(& &1.asset_type) |> Enum.uniq() |> Enum.join(", ")}
      """
    end
  end

  defp generate_debt_summary(debts) do
    if Enum.empty?(debts) do
      ""
    else
      total_debt = debts |> Enum.map(& &1.outstanding_balance) |> Enum.reduce(Money.new(0), &Money.add/2)
      
      """
      Debt Portfolio Summary:
      Total outstanding debt: #{Money.to_string(total_debt)}
      Number of debts: #{length(debts)}
      Debt types: #{debts |> Enum.map(& &1.debt_type) |> Enum.uniq() |> Enum.join(", ")}
      """
    end
  end

  defp generate_goals_summary(goals) do
    if Enum.empty?(goals) do
      ""
    else
      """
      Financial Goals Summary:
      Active goals: #{length(goals)}
      Goal types: #{goals |> Enum.map(& &1.goal_type) |> Enum.uniq() |> Enum.join(", ")}
      """
    end
  end

  defp generate_financial_profile(user_id) do
    """
    Financial Profile for User #{user_id}:
    This user has been actively managing their finances through the Soup & Nutz platform.
    Personalized advice should consider their specific financial situation and goals.
    """
  end
end