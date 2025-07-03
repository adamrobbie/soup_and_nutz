# AI LangChain Setup and Next Steps

## Quick Setup Guide

### 1. Install Dependencies

```bash
# Install the new AI-related dependencies
mix deps.get
```

### 2. Set Up Ollama (Recommended for Local Development)

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Pull recommended models
ollama pull llama3.1:8b      # General purpose, good reasoning
ollama pull mistral:7b       # Fast and efficient
ollama pull codellama:13b    # For code-related tasks
ollama pull phi3:mini        # Lightweight option
```

### 3. Configure Environment Variables

```bash
# Add to your .env or environment
export OLLAMA_BASE_URL=http://localhost:11434

# Optional: Add other AI providers
export OPENAI_API_KEY=your_openai_key_here
export ANTHROPIC_API_KEY=your_anthropic_key_here
```

### 4. Start the Application

```bash
# The LangChain service will start automatically
mix phx.server
```

## Testing the Implementation

### Basic Chat Test

```elixir
# In IEx console (iex -S mix)
user_id = 1

# Basic conversation
{:ok, response} = SoupAndNutz.AI.LangChainService.chat(
  "I have $50k in savings and $20k in credit card debt. What should I do?",
  user_id
)

IO.puts(response.text)
```

### Model Management Test

```elixir
# List available models
{:ok, models} = SoupAndNutz.AI.LangChainService.list_available_models()
IO.inspect(models)

# Switch models
{:ok, _model} = SoupAndNutz.AI.LangChainService.switch_model("mistral:7b")
```

### Financial Agent Test

```elixir
# Create sample user data
user_data = %{
  assets: [],
  debts: [%{debt_type: "credit_card", outstanding_balance: Money.new(2000000)}],
  income: Money.new(5000000),
  age: 30
}

# Get comprehensive financial analysis
{:ok, analysis} = SoupAndNutz.AI.FinancialAgent.comprehensive_analysis(
  user_data,
  %{name: "llama3.1:8b", provider: :ollama}
)

IO.inspect(analysis)
```

## Integration with Your Existing App

### 1. Add AI Chat to LiveViews

Create a new LiveView for AI interactions:

```elixir
# lib/soup_and_nutz_web/live/ai_assistant_live.ex
defmodule SoupAndNutzWeb.AIAssistantLive do
  use SoupAndNutzWeb, :live_view
  
  alias SoupAndNutz.AI.LangChainService
  
  def mount(_params, %{"user_id" => user_id}, socket) do
    {:ok, assign(socket, user_id: user_id, messages: [], input: "")}
  end
  
  def handle_event("send_message", %{"message" => message}, socket) do
    case LangChainService.chat(message, socket.assigns.user_id) do
      {:ok, response} ->
        new_messages = [
          %{type: :user, content: message},
          %{type: :assistant, content: response.text}
          | socket.assigns.messages
        ]
        {:noreply, assign(socket, messages: new_messages, input: "")}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "AI Error: #{reason}")}
    end
  end
end
```

### 2. Enhance Financial Analysis Pages

Add AI insights to existing financial pages:

```elixir
# In your existing LiveViews, add AI analysis
def handle_event("get_ai_insights", _params, socket) do
  user_data = build_user_financial_data(socket.assigns.current_user)
  
  case SoupAndNutz.AI.FinancialAgent.personalized_recommendations(user_data, get_current_model()) do
    {:ok, recommendations} ->
      {:noreply, assign(socket, ai_insights: recommendations)}
    {:error, reason} ->
      {:noreply, put_flash(socket, :error, "Could not generate insights: #{reason}")}
  end
end
```

### 3. Add AI to Goal Planning

Enhance your financial goals with AI planning:

```elixir
# When creating or updating goals
def create_goal_with_ai_plan(goal_attrs, user) do
  with {:ok, goal} <- FinancialGoals.create_goal(goal_attrs),
       user_financial_data <- gather_user_financial_data(user),
       {:ok, ai_plan} <- SoupAndNutz.AI.FinancialAgent.create_goal_plan(goal, user_financial_data, get_current_model()) do
    
    # Store the AI-generated plan with the goal
    FinancialGoals.update_goal(goal, %{ai_generated_plan: ai_plan})
  end
end
```

## Advanced Configuration

### Custom Model Selection

```elixir
# Configure model selection strategies per user or use case
config = %{
  user_preferences: %{
    response_speed: :fast,        # vs :balanced, :thorough
    analysis_depth: :comprehensive, # vs :standard, :quick
    writing_style: :professional   # vs :casual, :technical
  }
}

{:ok, response} = SoupAndNutz.AI.LangChainService.chat(
  "Help me plan my retirement",
  user_id,
  config
)
```

### RAG Knowledge Base Setup

```elixir
# Add financial knowledge documents to RAG
financial_guides = [
  "Investment strategies for beginners...",
  "Debt consolidation best practices...",
  "Retirement planning checklist..."
]

SoupAndNutz.AI.RAGChain.add_documents(
  rag_chain,
  financial_guides,
  %{source: "financial_education", type: "guide"}
)
```

## Performance Optimization

### 1. Caching Strategy

The system automatically caches embeddings and responses, but you can optimize further:

```elixir
# Configure caching in your environment
config :soup_and_nutz, :ai_cache,
  embedding_ttl: 3600,     # 1 hour
  response_ttl: 1800,      # 30 minutes
  max_cache_size: 1000     # entries
```

### 2. Background Processing

For expensive operations, use background jobs:

```elixir
# In your existing job processor
defmodule SoupAndNutz.AIAnalysisJob do
  def perform(user_id, analysis_type) do
    user_data = gather_user_data(user_id)
    
    case SoupAndNutz.AI.FinancialAgent.comprehensive_analysis(user_data, get_model()) do
      {:ok, analysis} ->
        # Store results and notify user
        store_analysis_results(user_id, analysis)
        notify_user_analysis_complete(user_id)
      {:error, reason} ->
        notify_user_analysis_failed(user_id, reason)
    end
  end
end
```

## Monitoring and Analytics

### Add Telemetry Events

```elixir
# Track AI usage
:telemetry.execute([:ai, :chat, :completed], %{
  response_time: response_time,
  model_used: model_name,
  user_id: user_id,
  success: true
})
```

### Performance Metrics

Monitor these key metrics:
- **Response Times**: Track model performance
- **Success Rates**: Monitor failure rates
- **User Engagement**: Chat frequency and satisfaction
- **Model Usage**: Which models are most effective
- **Cost Tracking**: Token usage and API costs

## Security Best Practices

### 1. Input Validation

```elixir
defmodule SoupAndNutz.AI.InputValidator do
  def validate_user_input(input) do
    input
    |> String.trim()
    |> validate_length()
    |> check_for_prompt_injection()
    |> sanitize_content()
  end
  
  defp validate_length(input) when byte_size(input) > 10_000 do
    {:error, "Input too long"}
  end
  defp validate_length(input), do: {:ok, input}
  
  defp check_for_prompt_injection({:ok, input}) do
    dangerous_patterns = ["ignore previous", "system:", "assistant:"]
    
    if Enum.any?(dangerous_patterns, &String.contains?(String.downcase(input), &1)) do
      {:error, "Invalid input detected"}
    else
      {:ok, input}
    end
  end
end
```

### 2. Rate Limiting

```elixir
# Add rate limiting per user
defmodule SoupAndNutz.AI.RateLimiter do
  def check_rate_limit(user_id) do
    key = "ai_requests:#{user_id}"
    current_requests = get_current_requests(key)
    
    if current_requests >= 100 do  # 100 requests per hour
      {:error, :rate_limited}
    else
      increment_requests(key)
      {:ok, :allowed}
    end
  end
end
```

## Next Steps

### Immediate Actions

1. **Test the System**: Run the test examples above
2. **Configure Models**: Set up your preferred Ollama models
3. **Add UI Components**: Create chat interfaces in your LiveViews
4. **Integrate Gradually**: Start with simple chat features

### Short-term Enhancements (1-2 weeks)

1. **Add Streaming**: Implement real-time response streaming
2. **Enhanced UI**: Build sophisticated chat interfaces
3. **Model Optimization**: Fine-tune model selection for your use cases
4. **Performance Monitoring**: Add comprehensive metrics

### Medium-term Goals (1-2 months)

1. **Vector Database**: Implement full pgvector integration
2. **Advanced RAG**: Build comprehensive financial knowledge base
3. **Custom Agents**: Create specialized agents for your specific needs
4. **User Personalization**: Implement user preference learning

### Long-term Vision (3-6 months)

1. **Multi-modal AI**: Add document and image analysis
2. **Advanced Analytics**: ML-powered usage optimization
3. **Custom Models**: Fine-tune models for your financial domain
4. **Enterprise Features**: SSO, admin controls, audit logs

## Troubleshooting

### Common Issues

**Ollama Not Responding:**
```bash
# Check if Ollama is running
ollama list

# Restart if needed
pkill ollama
ollama serve
```

**Model Not Found:**
```bash
# Pull the required model
ollama pull llama3.1:8b
```

**Memory Issues:**
- Reduce `max_history_length` in conversation memory
- Implement more aggressive caching cleanup
- Use smaller models for development

**Performance Issues:**
- Enable response caching
- Use local models for development
- Implement background job processing for heavy analysis

## Support and Resources

- **Ollama Documentation**: https://github.com/ollama/ollama
- **LangChain Concepts**: https://docs.langchain.com/
- **Elixir GenServer**: https://hexdocs.pm/elixir/GenServer.html

The sophisticated LangChain system is now ready for integration into your financial application. Start with simple chat features and gradually expand to more advanced AI-powered financial analysis capabilities!