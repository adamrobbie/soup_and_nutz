defmodule SoupAndNutz.MCP.Server do
  @moduledoc """
  Model Context Protocol (MCP) server for SoupAndNutz.

  This server provides structured access to:
  - Conversation data
  - AI system status
  - Vector database queries
  - System health metrics
  """

  use GenServer
  require Logger

  alias SoupAndNutz.AISystem
  alias SoupAndNutz.AISystem.{ConversationDB, VectorDB, HealthMonitor}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

    @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 3002)

    Logger.info("Starting MCP server on port #{port}")

    # Start the TCP server with error handling
    case :gen_tcp.listen(port, [:binary, {:packet, :line}, {:active, false}]) do
      {:ok, socket} ->
        # Start accepting connections
        spawn_link(fn -> accept_connections(socket) end)
        {:ok, %{port: port, socket: socket}}

      {:error, :eaddrinuse} ->
        Logger.error("Port #{port} is already in use. Trying port #{port + 1}")
        init([port: port + 1])

      {:error, reason} ->
        Logger.error("Failed to start MCP server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  defp accept_connections(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        spawn_link(fn -> handle_client(client) end)
        accept_connections(socket)
      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
    end
  end

  defp handle_client(client) do
    case handle_mcp_protocol(client) do
      :ok -> :gen_tcp.close(client)
      {:error, reason} ->
        Logger.error("MCP client error: #{inspect(reason)}")
        :gen_tcp.close(client)
    end
  end

  defp handle_mcp_protocol(client) do
    # Send initial handshake
    send_response(client, %{
      jsonrpc: "2.0",
      id: 1,
      result: %{
        protocolVersion: "2024-11-05",
        capabilities: %{
          tools: %{},
          resources: %{},
          prompts: %{}
        },
        serverInfo: %{
          name: "SoupAndNutz MCP Server",
          version: "1.0.0"
        }
      }
    })

    # Handle incoming requests
    handle_requests(client)
  end

  defp handle_requests(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, request} ->
            response = process_request(request)
            send_response(client, response)
            handle_requests(client)
          {:error, reason} ->
            Logger.error("Failed to parse JSON: #{inspect(reason)}")
            {:error, :invalid_json}
        end
      {:error, :closed} ->
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Process an MCP request and return the response.
  This function is public for testing purposes.
  """
  def process_request(%{"method" => "tools/list"}) do
    %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "result" => %{
        "tools" => [
          %{
            "name" => "get_conversation",
            "description" => "Get conversation history by ID",
            "inputSchema" => %{
              "type" => "object",
              "properties" => %{
                "conversation_id" => %{
                  "type" => "string",
                  "description" => "The conversation ID to retrieve"
                }
              },
              "required" => ["conversation_id"]
            }
          },
          %{
            "name" => "list_conversations",
            "description" => "List all conversations",
            "inputSchema" => %{
              "type" => "object",
              "properties" => %{}
            }
          },
          %{
            "name" => "search_conversations",
            "description" => "Search conversations by content",
            "inputSchema" => %{
              "type" => "object",
              "properties" => %{
                "query" => %{
                  "type" => "string",
                  "description" => "Search query"
                },
                "limit" => %{
                  "type" => "integer",
                  "description" => "Maximum number of results",
                  "default" => 10
                }
              },
              "required" => ["query"]
            }
          },
          %{
            "name" => "get_system_status",
            "description" => "Get AI system health and status",
            "inputSchema" => %{
              "type" => "object",
              "properties" => %{}
            }
          },
          %{
            "name" => "chat",
            "description" => "Send a message to the AI system",
            "inputSchema" => %{
              "type" => "object",
              "properties" => %{
                "message" => %{
                  "type" => "string",
                  "description" => "Message to send to AI"
                },
                "conversation_id" => %{
                  "type" => "string",
                  "description" => "Conversation ID (optional)"
                }
              },
              "required" => ["message"]
            }
          }
        ]
      }
    }
  end

  def process_request(%{"method" => "tools/call", "params" => %{"name" => tool_name, "arguments" => args}}) do
    result = case tool_name do
      "get_conversation" ->
        conversation_id = args["conversation_id"]
        case ConversationDB.get_conversation_by_external_id(conversation_id) do
          nil -> %{error: "Conversation not found"}
          conversation -> %{
            id: conversation.external_id,
            messages: Enum.map(conversation.messages, fn msg ->
              %{
                role: msg.role,
                content: msg.content,
                inserted_at: msg.inserted_at
              }
            end)
          }
        end

      "list_conversations" ->
        conversations = ConversationDB.list_conversations()
        Enum.map(conversations, fn conv ->
          %{
            id: conv.external_id,
            message_count: length(conv.messages),
            created_at: conv.inserted_at
          }
        end)

      "search_conversations" ->
        query = args["query"]
        limit = args["limit"] || 10

        # Use vector search to find similar content
        case search_conversations_by_content(query, limit) do
          {:ok, results} -> results
          {:error, reason} -> %{error: reason}
        end

      "get_system_status" ->
        HealthMonitor.get_system_status()

      "chat" ->
        message = args["message"]
        conversation_id = args["conversation_id"] || "mcp_#{System.system_time()}"

        case AISystem.chat(message, conversation_id: conversation_id) do
          {:ok, response} -> %{response: response, conversation_id: conversation_id}
          {:error, reason} -> %{error: reason}
        end

      _ ->
        %{error: "Unknown tool: #{tool_name}"}
    end

    %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "result" => %{"content" => [%{"type" => "text", "text" => Jason.encode!(result)}]}
    }
  end

  def process_request(_) do
    %{
      "jsonrpc" => "2.0",
      "id" => 1,
      "error" => %{
        "code" => -32601,
        "message" => "Method not found"
      }
    }
  end

  defp search_conversations_by_content(query, limit) do
    # Generate embedding for the query
    case SoupAndNutz.AISystem.EmbeddingService.generate_embedding(query) do
      {:ok, embedding} ->
        # Search for similar content
        case VectorDB.find_similar_embeddings(embedding, limit, 0.7) do
          {:ok, results} ->
            # Group by conversation and format results
            results
            |> Enum.group_by(fn r -> r["conversation_id"] end)
            |> Enum.map(fn {conv_id, messages} ->
              %{
                conversation_id: conv_id,
                messages: Enum.map(messages, fn msg ->
                  %{
                    content: msg["content"],
                    similarity: msg["similarity"]
                  }
                end)
              }
            end)
            |> then(&{:ok, &1})

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_response(client, response) do
    json = Jason.encode!(response)
    :gen_tcp.send(client, json <> "\n")
  end
end
