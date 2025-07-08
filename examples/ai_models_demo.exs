#!/usr/bin/env elixir

# AI Models Demonstration Script
# Run with: elixir examples/ai_models_demo.exs

# Ensure the application is started
Application.ensure_all_started(:soup_and_nutz)

defmodule AIModelsDemo do
  alias SoupAndNutz.AISystem
  alias SoupAndNutz.AISystem.ModelProvider

  def run do
    IO.puts("🤖 AI Models Demonstration")
    IO.puts("=" |> String.duplicate(50))

    # Show available models
    IO.puts("\n📋 Available Models:")
    show_available_models()

    # Test different model providers
    IO.puts("\n🧪 Testing Different Model Providers:")

    # Test OpenAI (if API key is available)
    test_openai_model()

    # Test Ollama (if running)
    test_ollama_model()

    # Test other local models
    test_local_models()

    IO.puts("\n✅ Demonstration completed!")
  end

  defp show_available_models do
    models = ModelProvider.available_models()

    Enum.each(models, fn model ->
      status = case model.provider do
        :openai ->
          if System.get_env("OPENAI_API_KEY"), do: "✅ Available", else: "❌ No API Key"
        :ollama ->
          if check_ollama_health(), do: "✅ Running", else: "❌ Not Running"
        :anthropic ->
          if System.get_env("ANTHROPIC_API_KEY"), do: "✅ Available", else: "❌ No API Key"
        :local -> "🔧 Configurable"
      end

      IO.puts("  #{model.name} (#{model.provider}) - #{status}")
      IO.puts("    #{model.description}")
    end)
  end

  defp test_openai_model do
    IO.puts("\n🔑 Testing OpenAI Model:")

    case System.get_env("OPENAI_API_KEY") do
      nil ->
        IO.puts("  ⚠️ OPENAI_API_KEY not set. Skipping OpenAI test.")

      _api_key ->
        IO.puts("  ✅ OpenAI API key found")

        # Create a worker with OpenAI model
        config = %{
          model: %{
            provider: :openai,
            model: "gpt-3.5-turbo",
            temperature: 0.7
          }
        }

        case AISystem.add_worker("openai_worker", config) do
          {:ok, _pid} ->
            IO.puts("  ✅ OpenAI worker created successfully")

            # Test the worker
            test_worker_with_message("openai_worker", "Hello! What's 2+2?")

            # Clean up
            AISystem.remove_worker("openai_worker")

          {:error, reason} ->
            IO.puts("  ❌ Failed to create OpenAI worker: #{inspect(reason)}")
        end
    end
  end

  defp test_ollama_model do
    IO.puts("\n🐙 Testing Ollama Model:")

    if check_ollama_health() do
      IO.puts("  ✅ Ollama is running")

      # Create a worker with Ollama model
      config = %{
        model: %{
          provider: :ollama,
          model: "phi",
          base_url: "http://localhost:11434",
          temperature: 0.7
        }
      }

      case AISystem.add_worker("ollama_worker", config) do
        {:ok, _pid} ->
          IO.puts("  ✅ Ollama worker created successfully")

          # Test the worker
          test_worker_with_message("ollama_worker", "Hello! What's 2+2?")

          # Clean up
          AISystem.remove_worker("ollama_worker")

        {:error, reason} ->
          IO.puts("  ❌ Failed to create Ollama worker: #{inspect(reason)}")
      end
    else
      IO.puts("  ⚠️ Ollama is not running. Start it with: docker-compose -f docker-compose.ai.yml up ollama")
    end
  end

  defp test_local_models do
    IO.puts("\n🏠 Testing Local Models:")

    # Test vLLM (OpenAI-compatible API)
    test_vllm_model()

    # Test LM Studio
    test_lmstudio_model()

    # Test GPT4All
    test_gpt4all_model()
  end

  defp test_vllm_model do
    IO.puts("  🚀 Testing vLLM:")

    if check_service_health("http://localhost:8000/v1/models") do
      config = %{
        model: %{
          provider: :local,
          model: "meta-llama/Llama-2-7b-chat-hf",
          base_url: "http://localhost:8000/v1",
          temperature: 0.7
        }
      }

      case AISystem.add_worker("vllm_worker", config) do
        {:ok, _pid} ->
          IO.puts("    ✅ vLLM worker created successfully")
          test_worker_with_message("vllm_worker", "Hello! What's 2+2?")
          AISystem.remove_worker("vllm_worker")

        {:error, reason} ->
          IO.puts("    ❌ Failed to create vLLM worker: #{inspect(reason)}")
      end
    else
      IO.puts("    ⚠️ vLLM not running. Start with: docker-compose -f docker-compose.ai.yml --profile vllm up")
    end
  end

  defp test_lmstudio_model do
    IO.puts("  🎯 Testing LM Studio:")

    if check_service_health("http://localhost:1234/v1/models") do
      config = %{
        model: %{
          provider: :local,
          model: "local-model",
          base_url: "http://localhost:1234/v1",
          temperature: 0.7
        }
      }

      case AISystem.add_worker("lmstudio_worker", config) do
        {:ok, _pid} ->
          IO.puts("    ✅ LM Studio worker created successfully")
          test_worker_with_message("lmstudio_worker", "Hello! What's 2+2?")
          AISystem.remove_worker("lmstudio_worker")

        {:error, reason} ->
          IO.puts("    ❌ Failed to create LM Studio worker: #{inspect(reason)}")
      end
    else
      IO.puts("    ⚠️ LM Studio not running. Start with: docker-compose -f docker-compose.ai.yml --profile lmstudio up")
    end
  end

  defp test_gpt4all_model do
    IO.puts("  🎪 Testing GPT4All:")

    if check_service_health("http://localhost:4891/v1/models") do
      config = %{
        model: %{
          provider: :local,
          model: "gpt4all-j",
          base_url: "http://localhost:4891/v1",
          temperature: 0.7
        }
      }

      case AISystem.add_worker("gpt4all_worker", config) do
        {:ok, _pid} ->
          IO.puts("    ✅ GPT4All worker created successfully")
          test_worker_with_message("gpt4all_worker", "Hello! What's 2+2?")
          AISystem.remove_worker("gpt4all_worker")

        {:error, reason} ->
          IO.puts("    ❌ Failed to create GPT4All worker: #{inspect(reason)}")
      end
    else
      IO.puts("    ⚠️ GPT4All not running. Start with: docker-compose -f docker-compose.ai.yml --profile gpt4all up")
    end
  end

  defp test_worker_with_message(worker_id, message) do
    IO.puts("    💬 Testing message: #{message}")

    case AISystem.AIWorker.process_message(worker_id, message) do
      {:ok, response} ->
        IO.puts("    🤖 Response: #{String.slice(response, 0, 100)}...")

      {:error, :circuit_breaker_open} ->
        IO.puts("    🔌 Circuit breaker is open")

      {:error, reason} ->
        IO.puts("    ❌ Error: #{inspect(reason)}")
    end
  end

  defp check_ollama_health do
    check_service_health("http://localhost:11434/api/tags")
  end

  defp check_service_health(url) do
    case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
      {:ok, {{_, 200, _}, _, _}} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  def show_setup_instructions do
    IO.puts("\n📖 Setup Instructions:")
    IO.puts("=" |> String.duplicate(50))

    IO.puts("\n1. 🐙 Ollama Setup:")
    IO.puts("   docker-compose -f docker-compose.ai.yml up ollama")
    IO.puts("   # Then pull a model:")
    IO.puts("   curl -X POST http://localhost:11434/api/pull -d '{\"name\": \"llama2\"}'")

    IO.puts("\n2. 🚀 vLLM Setup (High Performance):")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile vllm up")

    IO.puts("\n3. 🎯 LM Studio Setup:")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile lmstudio up")

    IO.puts("\n4. 🎪 GPT4All Setup (Lightweight):")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile gpt4all up")

    IO.puts("\n5. 🏠 LocalAI Setup:")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile localai up")

    IO.puts("\n6. 🔧 OpenLLM Setup:")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile openllm up")

    IO.puts("\n7. 🌐 Text Generation WebUI Setup:")
    IO.puts("   docker-compose -f docker-compose.ai.yml --profile textgen up")
    IO.puts("   # Access web interface at: http://localhost:7860")
  end
end

# Run the demonstration
AIModelsDemo.run()

# Show setup instructions
AIModelsDemo.show_setup_instructions()
