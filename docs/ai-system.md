# Fault-Tolerant AI System

A robust, fault-tolerant AI system built with LangChain and Elixir OTP, designed for high availability and scalability.

## Features

- **Circuit Breaker Pattern**: Automatically handles AI service failures and prevents cascading failures
- **Dynamic Worker Pools**: Load balancing across multiple AI workers with round-robin distribution
- **Supervision Trees**: Automatic process restart and recovery using Elixir OTP
- **Conversation Persistence**: Maintains conversation history across sessions
- **Health Monitoring**: Real-time system health checks and status reporting
- **LangChain Integration**: Seamless integration with LangChain for AI model interactions

## Architecture

```
SoupAndNutz.AISystem.Application
└── SoupAndNutz.AISystem.AISupervisor
    ├── SoupAndNutz.AISystem.CircuitBreaker
    ├── Registry (WorkerRegistry)
    ├── SoupAndNutz.AISystem.AIWorkerSupervisor
    │   └── SoupAndNutz.AISystem.AIWorker (dynamic)
    ├── SoupAndNutz.AISystem.MessageRouter
    ├── SoupAndNutz.AISystem.ConversationManager
    └── SoupAndNutz.AISystem.HealthMonitor
```

## Quick Start

### 1. Setup Environment Variables

```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"  # Optional
```

### 2. Basic Usage

```elixir
# Simple chat
{:ok, response} = SoupAndNutz.AISystem.chat("Hello, how are you?")

# Chat with conversation ID
{:ok, response} = SoupAndNutz.AISystem.chat("What's the weather like?", 
  conversation_id: "user_123")

# Chat with custom context and functions
custom_function = LangChain.Function.new!(%{
  name: "get_weather",
  description: "Get weather for a location",
  parameters_schema: %{
    type: "object",
    properties: %{location: %{type: "string"}},
    required: ["location"]
  },
  function: fn %{"location" => location}, _context ->
    {:ok, "Weather in #{location}: Sunny, 25°C"}
  end
})

{:ok, response} = SoupAndNutz.AISystem.chat(
  "What's the weather like in Paris?",
  context: %{functions: [custom_function]}
)
```

### 3. System Management

```elixir
# Check system health
status = SoupAndNutz.AISystem.system_status()

# Get conversation history
history = SoupAndNutz.AISystem.get_conversation_history("user_123")

# Scale workers dynamically
SoupAndNutz.AISystem.add_worker("worker_4")
SoupAndNutz.AISystem.remove_worker("worker_1")
```

## Configuration

### Environment Variables

- `OPENAI_API_KEY`: Your OpenAI API key (required)
- `ANTHROPIC_API_KEY`: Your Anthropic API key (optional)

### Application Configuration

```elixir
# config/config.exs
config :soup_and_nutz, :ai_system,
  worker_pool_size: 3,
  circuit_breaker_threshold: 5,
  circuit_breaker_timeout: 30_000
```

## Components

### Circuit Breaker

The circuit breaker pattern prevents cascading failures by monitoring AI service calls:

- **Closed State**: Normal operation, calls pass through
- **Open State**: Service is failing, calls are rejected immediately
- **Half-Open State**: Testing if service has recovered

```elixir
# Circuit breaker automatically handles failures
{:ok, response} = SoupAndNutz.AISystem.CircuitBreaker.call_ai_service(fn ->
  # Your AI service call here
  ai_service_call()
end)
```

### AI Workers

Individual worker processes that handle LangChain interactions:

```elixir
# Create a worker with custom configuration
config = %{
  llm: %{
    model: "gpt-4",
    temperature: 0.7
  },
  verbose: true
}

SoupAndNutz.AISystem.add_worker("custom_worker", config)
```

### Message Router

Load balances messages across available workers using round-robin:

```elixir
# Route a message through the load balancer
{:ok, response} = SoupAndNutz.AISystem.MessageRouter.route_message(
  "Hello, AI!",
  %{context: "additional context"}
)
```

### Conversation Manager

Persists conversation history in memory (can be extended to use database):

```elixir
# Save a message-response pair
SoupAndNutz.AISystem.ConversationManager.save_message(
  "conversation_123",
  "User message",
  "AI response"
)

# Retrieve conversation history
history = SoupAndNutz.AISystem.ConversationManager.get_conversation("conversation_123")
```

### Health Monitor

Performs periodic health checks on all system components:

```elixir
# Get current system status
status = SoupAndNutz.AISystem.HealthMonitor.get_system_status()
# Returns: %{status: :healthy, last_check: ~U[2024-01-01 12:00:00Z]}
```

## Advanced Usage

### Custom LangChain Functions

```elixir
# Define a custom function
weather_function = LangChain.Function.new!(%{
  name: "get_weather",
  description: "Get current weather for a location",
  parameters_schema: %{
    type: "object",
    properties: %{
      location: %{type: "string", description: "City name"},
      unit: %{type: "string", enum: ["celsius", "fahrenheit"], default: "celsius"}
    },
    required: ["location"]
  },
  function: fn params, _context ->
    # Your weather API call here
    {:ok, "Weather in #{params["location"]}: 22°C, Sunny"}
  end
})

# Use in chat
{:ok, response} = SoupAndNutz.AISystem.chat(
  "What's the weather in Tokyo?",
  context: %{functions: [weather_function]}
)
```

### Error Handling

```elixir
case SoupAndNutz.AISystem.chat("Hello") do
  {:ok, response} ->
    # Handle successful response
    IO.puts("AI: #{response}")
    
  {:error, :circuit_breaker_open} ->
    # Handle circuit breaker open
    IO.puts("AI service temporarily unavailable")
    
  {:error, reason} ->
    # Handle other errors
    IO.puts("Error: #{inspect(reason)}")
end
```

### Monitoring and Observability

```elixir
# Check system health
status = SoupAndNutz.AISystem.system_status()

# Monitor worker pool
worker_count = Registry.count(SoupAndNutz.AISystem.WorkerRegistry)

# Get conversation statistics
conversation_count = length(SoupAndNutz.AISystem.ConversationManager.get_all_conversations())
```

## Testing

Run the AI system tests:

```bash
mix test test/soup_and_nutz/ai_system_test.exs
```

## Production Considerations

### Database Integration

For production, consider replacing the in-memory conversation storage with a database:

```elixir
# Example: Use Ecto for conversation persistence
defmodule SoupAndNutz.AISystem.ConversationManager do
  use GenServer
  alias SoupAndNutz.Repo
  alias SoupAndNutz.Conversation

  def save_message(conversation_id, message, response) do
    %Conversation{}
    |> Conversation.changeset(%{
      conversation_id: conversation_id,
      message: message,
      response: response,
      timestamp: DateTime.utc_now()
    })
    |> Repo.insert()
  end
end
```

### Metrics and Monitoring

Add telemetry events for monitoring:

```elixir
# In your AI worker
defp process_with_langchain(message, context, state) do
  :telemetry.execute([:ai_system, :message_processed], %{
    worker_id: state.worker_id,
    message_length: String.length(message)
  })
  
  # ... existing processing logic
end
```

### Scaling

The system is designed to scale horizontally:

1. **Add more workers**: `SoupAndNutz.AISystem.add_worker("worker_#{n}")`
2. **Distribute across nodes**: Use Erlang distribution
3. **Load balancing**: The message router automatically distributes load

## Troubleshooting

### Common Issues

1. **Circuit Breaker Open**: AI service is failing repeatedly
   - Check API keys and network connectivity
   - Monitor error logs for specific failure reasons

2. **Worker Not Found**: Worker process has crashed
   - Check supervision tree: `Process.whereis(SoupAndNutz.AISystem.AIWorkerSupervisor)`
   - Review worker logs for crash reasons

3. **Memory Issues**: Large conversation histories
   - Implement conversation cleanup/archiving
   - Consider database storage for persistence

### Debug Commands

```elixir
# Check all processes
Process.list() |> Enum.filter(fn pid -> 
  Process.info(pid, :registered_name) |> elem(1) |> to_string() =~ "AISystem"
end)

# Monitor specific process
:observer.start()
```

## Contributing

When adding new features to the AI system:

1. Follow the supervision tree pattern
2. Add appropriate error handling
3. Include health monitoring
4. Write comprehensive tests
5. Update documentation

## License

This AI system is part of the SoupAndNutz project and follows the same licensing terms. 