defmodule SoupAndNutz.MCP.Client do
  @moduledoc """
  MCP client for testing the MCP server functionality.
  """

  require Logger

  @doc """
  Connect to the MCP server and test basic functionality.
  """
  def test_connection(host \\ "localhost", port \\ 3002) do
    case :gen_tcp.connect(String.to_charlist(host), port, [:binary, {:packet, :line}]) do
      {:ok, socket} ->
        Logger.info("Connected to MCP server")

        # Test tools/list
        test_list_tools(socket)

        # Test tools/call
        test_tools_call(socket)

        :gen_tcp.close(socket)
        {:ok, "MCP tests completed"}

      {:error, reason} ->
        Logger.error("Failed to connect to MCP server: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp test_list_tools(socket) do
    request = %{
      jsonrpc: "2.0",
      id: 1,
      method: "tools/list"
    }

    send_request(socket, request)
    response = receive_response(socket)

    Logger.info("Tools list response: #{inspect(response)}")
    response
  end

  defp test_tools_call(socket) do
    # Test get_system_status
    status_request = %{
      jsonrpc: "2.0",
      id: 2,
      method: "tools/call",
      params: %{
        name: "get_system_status",
        arguments: %{}
      }
    }

    send_request(socket, status_request)
    status_response = receive_response(socket)
    Logger.info("System status response: #{inspect(status_response)}")

    # Test chat
    chat_request = %{
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: %{
        name: "chat",
        arguments: %{
          message: "Hello! What is 2+2?",
          conversation_id: "test_mcp"
        }
      }
    }

    send_request(socket, chat_request)
    chat_response = receive_response(socket)
    Logger.info("Chat response: #{inspect(chat_response)}")

    [status_response, chat_response]
  end

  defp send_request(socket, request) do
    json = Jason.encode!(request)
    :gen_tcp.send(socket, json <> "\n")
  end

  defp receive_response(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, response} -> response
          {:error, reason} -> {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end
end
