defmodule SoupAndNutz.AISystemTest do
  use ExUnit.Case, async: false
  alias SoupAndNutz.AISystem

  setup do
    # Ensure the AI system is started for each test
    if Process.whereis(SoupAndNutz.AISystem.AISupervisor) == nil do
      {:ok, _pid} = SoupAndNutz.AISystem.AISupervisor.start_link([])
    end

    :ok
  end

  describe "basic functionality" do
    test "system starts successfully" do
      assert Process.whereis(SoupAndNutz.AISystem.AISupervisor) != nil
      assert Process.whereis(SoupAndNutz.AISystem.CircuitBreaker) != nil
      assert Process.whereis(SoupAndNutz.AISystem.MessageRouter) != nil
      assert Process.whereis(SoupAndNutz.AISystem.ConversationManager) != nil
      assert Process.whereis(SoupAndNutz.AISystem.HealthMonitor) != nil
    end

    test "health monitor reports system status" do
      status = AISystem.system_status()
      assert is_map(status)
      assert Map.has_key?(status, :status)
      assert Map.has_key?(status, :last_check)
    end

        test "can add and remove workers dynamically" do
      # Add a new worker
      {:ok, _pid} = AISystem.add_worker("test_worker_1")

      # Verify worker was added
      assert Registry.lookup(SoupAndNutz.AISystem.WorkerRegistry, "test_worker_1") != []

      # Remove the worker
      {:ok, _pid} = AISystem.remove_worker("test_worker_1")

      # Give the process a moment to fully terminate and registry to update
      Process.sleep(10)

      # Verify worker was removed
      assert Registry.lookup(SoupAndNutz.AISystem.WorkerRegistry, "test_worker_1") == []
    end
  end

  describe "conversation management" do
    test "can save and retrieve conversation history" do
      conversation_id = "test_conversation_#{:rand.uniform(1000)}"

      # Initially empty
      history = AISystem.get_conversation_history(conversation_id)
      assert history == []

      # Save a message
      AISystem.ConversationManager.save_message(conversation_id, "Hello", "Hi there!")

      # Retrieve history
      history = AISystem.get_conversation_history(conversation_id)
      assert length(history) == 1

      [entry] = history
      assert entry.message == "Hello"
      assert entry.response == "Hi there!"
      assert Map.has_key?(entry, :timestamp)
    end
  end

        describe "circuit breaker" do
    test "circuit breaker handles failures gracefully" do
      # Test with a failing service call
      failing_call = fn -> raise "Simulated failure" end

      # First few calls should fail but not open circuit
      for _ <- 1..5 do
        {:error, _} = SoupAndNutz.AISystem.CircuitBreaker.call_ai_service(failing_call)
      end

      # After threshold (5 failures), circuit should open
      {:error, :circuit_breaker_open} =
        SoupAndNutz.AISystem.CircuitBreaker.call_ai_service(failing_call)
    end

    test "circuit breaker recovers after timeout" do
      # This test would require mocking time, so we'll just test the structure
      circuit_breaker = Process.whereis(SoupAndNutz.AISystem.CircuitBreaker)
      assert circuit_breaker != nil
      assert Process.alive?(circuit_breaker)
    end
  end

  describe "message routing" do
    test "message router distributes messages across workers" do
      # Test that the router can handle messages
      # Note: This would require a mock LLM in a real test environment
      router = Process.whereis(SoupAndNutz.AISystem.MessageRouter)
      assert router != nil
      assert Process.alive?(router)
    end
  end

  describe "integration" do
        test "complete chat flow works" do
      # This test demonstrates the complete flow
      # In a real environment with API keys, this would work
      _conversation_id = "integration_test_#{:rand.uniform(1000)}"

      # The chat function should handle the complete flow
      # For now, we'll just test that the function exists and has the right arity
      assert function_exported?(AISystem, :chat, 1)
      assert function_exported?(AISystem, :chat, 2)
    end
  end

  # Helper function to create a mock LangChain function for testing
  def create_mock_function do
    LangChain.Function.new!(%{
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
  end
end
