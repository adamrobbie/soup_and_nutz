#!/usr/bin/env elixir

# MCP (Model Context Protocol) Integration Demo
# Run with: mix run examples/mcp_demo.exs

# Ensure the application is started
Application.ensure_all_started(:soup_and_nutz)

defmodule MCPDemo do
  alias SoupAndNutz.MCP.Client
  alias SoupAndNutz.AISystem

  def run do
    IO.puts("🔌 MCP (Model Context Protocol) Integration Demo")
    IO.puts("=" |> String.duplicate(60))

    # First, let's create some test data
    IO.puts("\n📝 Creating test conversations...")
    create_test_conversations()

    # Test MCP server connection
    IO.puts("\n🔗 Testing MCP server connection...")
    test_mcp_connection()

    # Test individual MCP tools
    IO.puts("\n🛠️ Testing MCP tools...")
    test_mcp_tools()

    IO.puts("\n✅ MCP demo completed!")
  end

  defp create_test_conversations do
    # Create a few test conversations
    conversations = [
      {"demo_conv_1", "What is the capital of France?", "The capital of France is Paris."},
      {"demo_conv_2", "How do I calculate compound interest?", "Compound interest is calculated using the formula A = P(1 + r/n)^(nt) where A is the final amount, P is the principal, r is the annual interest rate, n is the number of times interest is compounded per year, and t is the time in years."},
      {"demo_conv_3", "What are the benefits of exercise?", "Exercise has many benefits including improved cardiovascular health, stronger muscles and bones, better mental health, increased energy levels, and weight management."}
    ]

    Enum.each(conversations, fn {conv_id, question, answer} ->
      IO.puts("  💬 Creating conversation: #{conv_id}")

      # Send a message to create the conversation
      case AISystem.chat(question, conversation_id: conv_id) do
        {:ok, _response} ->
          # The AI system will automatically save the conversation
          IO.puts("    ✅ Created conversation with question")

        {:error, reason} ->
          IO.puts("    ❌ Failed to create conversation: #{inspect(reason)}")
      end
    end)
  end

  defp test_mcp_connection do
    case Client.test_connection() do
      {:ok, message} ->
        IO.puts("  ✅ #{message}")

      {:error, reason} ->
        IO.puts("  ❌ MCP connection failed: #{inspect(reason)}")
        IO.puts("     Make sure the MCP server is running on port 3002")
    end
  end

  defp test_mcp_tools do
    # Test each tool individually
    tools = [
      {"get_system_status", %{}},
      {"list_conversations", %{}},
      {"get_conversation", %{conversation_id: "demo_conv_1"}},
      {"search_conversations", %{query: "capital", limit: 5}},
      {"chat", %{message: "What is the square root of 16?", conversation_id: "mcp_test"}}
    ]

    Enum.each(tools, fn {tool_name, args} ->
      IO.puts("  🛠️ Testing tool: #{tool_name}")
      test_tool(tool_name, args)
    end)
  end

  defp test_tool(tool_name, args) do
          case :gen_tcp.connect(String.to_charlist("localhost"), 3002, [:binary, {:packet, :line}]) do
      {:ok, socket} ->
        request = %{
          jsonrpc: "2.0",
          id: System.system_time(),
          method: "tools/call",
          params: %{
            name: tool_name,
            arguments: args
          }
        }

        json = Jason.encode!(request)
        :gen_tcp.send(socket, json <> "\n")

        case :gen_tcp.recv(socket, 0) do
          {:ok, data} ->
            case Jason.decode(data) do
              {:ok, response} ->
                case response do
                  %{"result" => %{"content" => [%{"text" => text}]}} ->
                    result = Jason.decode!(text)
                    IO.puts("    ✅ #{tool_name}: #{inspect(result, pretty: true)}")

                  %{"error" => error} ->
                    IO.puts("    ❌ #{tool_name} error: #{inspect(error)}")

                  _ ->
                    IO.puts("    ⚠️ #{tool_name}: Unexpected response format")
                end

              {:error, reason} ->
                IO.puts("    ❌ #{tool_name}: JSON decode error: #{inspect(reason)}")
            end

          {:error, reason} ->
            IO.puts("    ❌ #{tool_name}: TCP receive error: #{inspect(reason)}")
        end

        :gen_tcp.close(socket)

      {:error, reason} ->
        IO.puts("    ❌ #{tool_name}: Connection failed: #{inspect(reason)}")
    end
  end
end

# Run the demo
MCPDemo.run()
