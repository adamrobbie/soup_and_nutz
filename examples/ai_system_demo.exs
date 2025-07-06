#!/usr/bin/env elixir

# AI System Demonstration Script
# Run with: elixir examples/ai_system_demo.exs

# Ensure the application is started
Application.ensure_all_started(:soup_and_nutz)

defmodule AISystemDemo do
  alias SoupAndNutz.AISystem

  def run do
    IO.puts("🤖 AI System Demonstration")
    IO.puts("=" |> String.duplicate(50))

    # Check system health
    IO.puts("\n📊 Checking system health...")
    status = AISystem.system_status()
    IO.puts("System status: #{status.status}")
    IO.puts("Last check: #{status.last_check}")

    # Test basic functionality
    IO.puts("\n🧪 Testing basic functionality...")
    test_basic_functionality()

    # Test conversation management
    IO.puts("\n💬 Testing conversation management...")
    test_conversation_management()

    # Test worker management
    IO.puts("\n⚙️ Testing worker management...")
    test_worker_management()

    # Test circuit breaker
    IO.puts("\n🔌 Testing circuit breaker...")
    test_circuit_breaker()

    IO.puts("\n✅ Demonstration completed!")
  end

  defp test_basic_functionality do
    # Test that all core processes are running
    processes = [
      SoupAndNutz.AISystem.AISupervisor,
      SoupAndNutz.AISystem.CircuitBreaker,
      SoupAndNutz.AISystem.MessageRouter,
      SoupAndNutz.AISystem.ConversationManager,
      SoupAndNutz.AISystem.HealthMonitor
    ]

    Enum.each(processes, fn process ->
      case Process.whereis(process) do
        nil -> IO.puts("❌ #{process} is not running")
        pid when is_pid(pid) ->
          if Process.alive?(pid) do
            IO.puts("✅ #{process} is running (PID: #{inspect(pid)})")
          else
            IO.puts("❌ #{process} is not alive")
          end
      end
    end)
  end

  defp test_conversation_management do
    conversation_id = "demo_conversation_#{:rand.uniform(1000)}"

    # Save some test messages
    messages = [
      {"Hello, AI!", "Hi there! How can I help you today?"},
      {"What's 2+2?", "2+2 equals 4."},
      {"Tell me a joke", "Why don't scientists trust atoms? Because they make up everything! 😄"}
    ]

    Enum.each(messages, fn {message, response} ->
      AISystem.ConversationManager.save_message(conversation_id, message, response)
      IO.puts("💾 Saved: #{message} -> #{response}")
    end)

    # Retrieve conversation history
    history = AISystem.get_conversation_history(conversation_id)
    IO.puts("📚 Conversation history has #{length(history)} messages")

    # Display recent messages
    history
    |> Enum.take(2)
    |> Enum.each(fn entry ->
      IO.puts("  📝 #{entry.message} -> #{entry.response}")
    end)
  end

  defp test_worker_management do
    # Add a new worker
    worker_id = "demo_worker_#{:rand.uniform(1000)}"
    IO.puts("➕ Adding worker: #{worker_id}")

    case AISystem.add_worker(worker_id) do
      {:ok, _pid} ->
        IO.puts("✅ Worker #{worker_id} added successfully")

        # Verify worker exists
        case Registry.lookup(SoupAndNutz.AISystem.WorkerRegistry, worker_id) do
          [{pid, _}] -> IO.puts("✅ Worker #{worker_id} found in registry (PID: #{inspect(pid)})")
          [] -> IO.puts("❌ Worker #{worker_id} not found in registry")
        end

        # Remove worker
        IO.puts("➖ Removing worker: #{worker_id}")
        case AISystem.remove_worker(worker_id) do
          {:ok, _pid} -> IO.puts("✅ Worker #{worker_id} removed successfully")
          {:error, reason} -> IO.puts("❌ Failed to remove worker: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to add worker: #{inspect(reason)}")
    end
  end

  defp test_circuit_breaker do
    IO.puts("🔌 Testing circuit breaker with failing calls...")

    # Create a function that fails
    failing_function = fn ->
      raise "Simulated AI service failure"
    end

    # Test circuit breaker behavior
    results = for i <- 1..6 do
      result = SoupAndNutz.AISystem.CircuitBreaker.call_ai_service(failing_function)
      IO.puts("  Call #{i}: #{inspect(result)}")
      result
    end

    # Check if circuit opened
    if Enum.any?(results, fn {:error, reason} -> reason == :circuit_breaker_open end) do
      IO.puts("✅ Circuit breaker opened as expected after failures")
    else
      IO.puts("⚠️ Circuit breaker did not open (may need more failures)")
    end
  end

  # Example of how to use the AI system with real API calls
  def demo_with_api do
    IO.puts("\n🚀 Demo with real API calls (requires OPENAI_API_KEY)...")

    # Check if API key is available
    case System.get_env("OPENAI_API_KEY") do
      nil ->
        IO.puts("⚠️ OPENAI_API_KEY not set. Skipping API demo.")
        IO.puts("   Set it with: export OPENAI_API_KEY='your-key-here'")

      api_key ->
        IO.puts("✅ API key found, attempting real AI call...")

        # Create a custom function for demonstration
        weather_function = LangChain.Function.new!(%{
          name: "get_weather",
          description: "Get weather for a location",
          parameters_schema: %{
            type: "object",
            properties: %{location: %{type: "string"}},
            required: ["location"]
          },
          function: fn %{"location" => location}, _context ->
            {:ok, "Weather in #{location}: Sunny, 25°C (simulated)"}
          end
        })

        # Try a chat with the AI system
        case AISystem.chat(
          "Hello! Can you tell me about the weather in Paris?",
          conversation_id: "api_demo",
          context: %{functions: [weather_function]}
        ) do
          {:ok, response} ->
            IO.puts("🤖 AI Response: #{response}")

          {:error, :circuit_breaker_open} ->
            IO.puts("🔌 Circuit breaker is open - AI service unavailable")

          {:error, reason} ->
            IO.puts("❌ Error: #{inspect(reason)}")
        end
    end
  end
end

# Run the demonstration
AISystemDemo.run()

# Uncomment the line below to test with real API calls
# AISystemDemo.demo_with_api()
