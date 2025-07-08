#!/usr/bin/env elixir

# OpenLLM Integration Demo
# This script demonstrates how to integrate OpenLLM with the AI system

defmodule OpenLLMDemo do
  @moduledoc """
  Demo script for OpenLLM integration with the AI system.

  Prerequisites:
  1. Start OpenLLM: make openllm
  2. Wait for OpenLLM to be ready (check http://localhost:3000/v1/models)
  """

  def run do
    IO.puts("🚀 OpenLLM Integration Demo")
    IO.puts("=" |> String.duplicate(50))

    # Check if OpenLLM is running
    if check_openllm_health() do
      IO.puts("✅ OpenLLM is running")
      test_openllm_integration()
    else
      IO.puts("❌ OpenLLM is not running")
      IO.puts("   Start it with: make openllm")
      IO.puts("   Then wait for it to be ready and run this demo again")
    end
  end

  defp test_openllm_integration do
    IO.puts("\n🔧 Testing OpenLLM Integration:")

    # Test different OpenLLM models
    test_models = [
      {"llama2-7b", "meta-llama/Llama-2-7b-chat-hf"},
      {"mistral-7b", "mistralai/Mistral-7B-Instruct-v0.2"},
      {"codellama-7b", "codellama/CodeLlama-7b-Instruct-hf"}
    ]

    Enum.each(test_models, fn {name, model} ->
      test_openllm_model(name, model)
    end)
  end

  defp test_openllm_model(name, model) do
    IO.puts("\n  🎯 Testing #{name}:")

    config = %{
      model: %{
        provider: :openllm,
        model: model,
        base_url: "http://localhost:3000/v1",
        temperature: 0.7,
        max_tokens: 512
      }
    }

    worker_id = "openllm_#{String.replace(name, "-", "_")}_worker"

    case AISystem.add_worker(worker_id, config) do
      {:ok, _pid} ->
        IO.puts("    ✅ #{name} worker created successfully")

        # Test basic conversation
        test_conversation(worker_id, "Hello! What's 2+2?")

        # Test model-specific capabilities
        case name do
          "codellama-7b" ->
            test_conversation(worker_id, "Write a Python function to calculate fibonacci numbers")
          "mistral-7b" ->
            test_conversation(worker_id, "Explain quantum computing in simple terms")
          _ ->
            test_conversation(worker_id, "What are the benefits of using OpenLLM?")
        end

        # Clean up
        AISystem.remove_worker(worker_id)

      {:error, reason} ->
        IO.puts("    ❌ Failed to create #{name} worker: #{inspect(reason)}")
    end
  end

  defp test_conversation(worker_id, message) do
    IO.puts("    💬 Testing: #{message}")

    case AISystem.AIWorker.process_message(worker_id, message) do
      {:ok, response} ->
        IO.puts("    🤖 Response: #{String.slice(response, 0, 150)}...")

      {:error, :circuit_breaker_open} ->
        IO.puts("    🔌 Circuit breaker is open")

      {:error, reason} ->
        IO.puts("    ❌ Error: #{inspect(reason)}")
    end
  end

  defp check_openllm_health do
    case :httpc.request(:get, {String.to_charlist("http://localhost:3000/v1/models"), []}, [], []) do
      {:ok, {{_, 200, _}, _, _}} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  def show_setup_instructions do
    IO.puts("\n📖 OpenLLM Setup Instructions:")
    IO.puts("=" |> String.duplicate(50))

    IO.puts("\n1. 🚀 Start OpenLLM:")
    IO.puts("   make openllm")

    IO.puts("\n2. ⏳ Wait for OpenLLM to be ready:")
    IO.puts("   curl http://localhost:3000/v1/models")

    IO.puts("\n3. 🎯 Test with different models:")
    IO.puts("   # Llama 2 (default)")
    IO.puts("   curl -X POST http://localhost:3000/v1/chat/completions \\")
    IO.puts("     -H 'Content-Type: application/json' \\")
    IO.puts("     -d '{\"model\": \"meta-llama/Llama-2-7b-chat-hf\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello!\"}]}'")

    IO.puts("\n4. 🔧 Environment Variables:")
    IO.puts("   OPENLLM_MODEL=meta-llama/Llama-2-7b-chat-hf")
    IO.puts("   OPENLLM_QUANTIZE=int4  # Reduce memory usage")
    IO.puts("   OPENLLM_MAX_MODEL_LEN=4096")

    IO.puts("\n5. 📊 Monitor OpenLLM:")
    IO.puts("   # Check logs")
    IO.puts("   docker-compose -f docker-compose.yml --profile ai logs openllm")
    IO.puts("   # Check metrics")
    IO.puts("   curl http://localhost:3000/metrics")

    IO.puts("\n6. 🛠️ Custom Models:")
    IO.puts("   # Pull a different model")
    IO.puts("   docker-compose -f docker-compose.yml --profile ai exec openllm openllm pull mistralai/Mistral-7B-Instruct-v0.2")
  end

  def show_performance_tips do
    IO.puts("\n⚡ Performance Tips:")
    IO.puts("=" |> String.duplicate(50))

    IO.puts("\n1. 🧠 Memory Optimization:")
    IO.puts("   - Use quantization (INT4, INT8) for lower memory usage")
    IO.puts("   - Smaller models (7B vs 13B) for development")
    IO.puts("   - Adjust max_model_len based on your needs")

    IO.puts("\n2. 🚀 Speed Optimization:")
    IO.puts("   - Use GPU acceleration when available")
    IO.puts("   - Enable batching for multiple requests")
    IO.puts("   - Use smaller context windows")

    IO.puts("\n3. 🔧 Configuration:")
    IO.puts("   - OPENLLM_QUANTIZE=int4  # 4-bit quantization")
    IO.puts("   - OPENLLM_MAX_MODEL_LEN=2048  # Smaller context")
    IO.puts("   - OPENLLM_DEVICE=cuda  # GPU acceleration")

    IO.puts("\n4. 📈 Monitoring:")
    IO.puts("   - Check /metrics endpoint for performance data")
    IO.puts("   - Monitor memory usage with docker stats")
    IO.puts("   - Use circuit breaker in your AI system")
  end
end

# Run the demonstration
OpenLLMDemo.run()

# Show setup instructions
OpenLLMDemo.show_setup_instructions()

# Show performance tips
OpenLLMDemo.show_performance_tips()
