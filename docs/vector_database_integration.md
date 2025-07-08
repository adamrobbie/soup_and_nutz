# Vector Database Integration with pgvector

This document describes the vector database integration using pgvector in PostgreSQL for the AI system.

## Overview

The vector database integration provides:
- **Text embedding storage** - Store embeddings as JSON data in PostgreSQL
- **Similarity search** - Find similar content using vector similarity
- **Context-aware search** - Search within specific users or conversations
- **Integration with AI system** - Automatic embedding generation and storage

## Architecture

### Database Schema

The vector database uses the following tables:

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Embeddings table
CREATE TABLE embeddings (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  embedding_data TEXT NOT NULL,  -- JSON array of floats
  embedding_vector VECTOR(1536), -- pgvector column for similarity search
  metadata JSONB DEFAULT '{}',
  user_id INTEGER REFERENCES users(id),
  conversation_id INTEGER REFERENCES conversations(id),
  message_id INTEGER REFERENCES messages(id),
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX ON embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON embeddings (user_id);
CREATE INDEX ON embeddings (conversation_id);
CREATE INDEX ON embeddings (message_id);
```

### Key Components

1. **Embedding Schema** (`lib/soup_and_nutz/ai_system/embedding.ex`)
   - Ecto schema for the embeddings table
   - Handles JSON serialization/deserialization

2. **VectorDB Context** (`lib/soup_and_nutz/ai_system/vector_db.ex`)
   - Database operations for embeddings
   - Similarity search functions
   - Mock similarity calculation (for testing)

3. **EmbeddingService** (`lib/soup_and_nutz/ai_system/embedding_service.ex`)
   - High-level service for embedding operations
   - Integration with AI system
   - Mock embedding generation (for testing)

## Usage

### Basic Operations

```elixir
# Generate an embedding
{:ok, embedding} = EmbeddingService.generate_embedding("Hello, world!")

# Store an embedding
{:ok, stored} = EmbeddingService.store_embedding("Hello, world!", embedding, %{"type" => "greeting"})

# Find similar content
{:ok, similar} = VectorDB.find_similar_embeddings(embedding, 10, 0.7)
```

### Context-Aware Search

```elixir
# Store with context
{:ok, stored} = EmbeddingService.store_embedding_with_context(
  "User message", 
  embedding, 
  user_id, 
  conversation_id, 
  message_id, 
  %{"type" => "message"}
)

# Find similar content for a user
{:ok, user_similar} = VectorDB.find_similar_embeddings_for_user(embedding, user_id, 5, 0.6)

# Find similar content in a conversation
{:ok, conv_similar} = VectorDB.find_similar_embeddings_for_conversation(embedding, conversation_id, 5, 0.6)
```

### AI System Integration

```elixir
# Process a message (automatically generates and stores embedding)
{:ok, stored} = EmbeddingService.process_message_embedding(
  "User message content", 
  user_id, 
  conversation_id, 
  message_id
)

# Get conversation context
{:ok, context} = EmbeddingService.get_conversation_context(
  "Current message", 
  conversation_id, 
  5
)
```

## Configuration

### Docker Setup

The pgvector database is configured in `docker-compose.yml`:

```yaml
postgres:
  image: pgvector/pgvector:pg16
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    POSTGRES_DB: soup_and_nutz_dev
  ports:
    - "5433:5432"
```

### Database Configuration

The database configuration is in `config/dev.exs`:

```elixir
config :soup_and_nutz, SoupAndNutz.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "soup_and_nutz_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

## Production Considerations

### Real OpenAI Integration

Replace the mock embedding generation with real OpenAI API calls:

```elixir
defp call_openai_embedding_api(text) do
  # Configure OpenAI API key
  api_key = System.get_env("OPENAI_API_KEY")
  
  # Call OpenAI embeddings API
  case Req.post("https://api.openai.com/v1/embeddings", 
    headers: [{"Authorization", "Bearer #{api_key}"}],
    json: %{
      input: text,
      model: "text-embedding-3-small"
    }
  ) do
    {:ok, %{body: %{"data" => [%{"embedding" => embedding}]}}} ->
      {:ok, embedding}
    
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Vector Similarity Search

Replace mock similarity calculation with real pgvector operations:

```elixir
def find_similar_embeddings(query_embedding, limit \\ 10, threshold \\ 0.7) do
  query_vector = Enum.join(query_embedding, ",")
  
  query = """
  SELECT e.*, 1 - (e.embedding_vector <=> $1::vector) as similarity
  FROM embeddings e
  WHERE 1 - (e.embedding_vector <=> $1::vector) > $2
  ORDER BY e.embedding_vector <=> $1::vector
  LIMIT $3
  """

  case Repo.query(query, [query_vector, threshold, limit]) do
    {:ok, %{rows: rows, columns: columns}} ->
      embeddings = Enum.map(rows, fn row ->
        Enum.zip(columns, row) |> Enum.into(%{})
      end)
      {:ok, embeddings}
    
    {:error, reason} ->
      {:error, reason}
  end
end
```

### Performance Optimization

1. **Index Tuning**: Adjust the `lists` parameter in the ivfflat index based on your data size
2. **Batch Operations**: Use batch inserts for multiple embeddings
3. **Connection Pooling**: Configure appropriate pool sizes
4. **Caching**: Consider caching frequently accessed embeddings

## Testing

Run the vector database tests:

```bash
mix test test/soup_and_nutz/ai_system/vector_db_test.exs
```

The tests cover:
- Basic embedding storage and retrieval
- Similarity search functionality
- Embedding generation
- Context-aware operations

## Migration

To set up the vector database:

```bash
# Start the database
docker-compose up postgres -d

# Run migrations
mix ecto.migrate
```

The migrations will:
1. Enable the pgvector extension
2. Create the embeddings table with proper indexes
3. Set up foreign key relationships

## Troubleshooting

### Common Issues

1. **pgvector extension not found**
   - Ensure you're using the `pgvector/pgvector:pg16` image
   - Check that the extension is enabled: `CREATE EXTENSION vector;`

2. **Vector type errors**
   - The current implementation stores vectors as JSON for compatibility
   - For production, implement proper pgvector type handling

3. **Performance issues**
   - Monitor query performance with `EXPLAIN ANALYZE`
   - Adjust index parameters based on data size
   - Consider partitioning for large datasets

### Debugging

Enable debug logging:

```elixir
config :logger, level: :debug
```

Check database connectivity:

```elixir
# In IEx
iex> SoupAndNutz.Repo.query("SELECT version()")
``` 