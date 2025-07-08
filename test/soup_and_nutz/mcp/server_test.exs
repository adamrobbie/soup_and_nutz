defmodule SoupAndNutz.MCP.ServerTest do
  use ExUnit.Case, async: false

  alias SoupAndNutz.MCP.Server

  @moduletag :unit

  test "process_request handles tools/list correctly" do
    request = %{"method" => "tools/list"}
    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["result"]["tools"] |> is_list()

    # Check that expected tools are present
    tool_names = Enum.map(response["result"]["tools"], & &1["name"])
    assert "get_conversation" in tool_names
    assert "list_conversations" in tool_names
    assert "search_conversations" in tool_names
    assert "get_system_status" in tool_names
    assert "chat" in tool_names
  end

  test "process_request handles unknown tool correctly" do
    request = %{
      "method" => "tools/call",
      "params" => %{
        "name" => "unknown_tool",
        "arguments" => %{}
      }
    }

    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["result"]["content"] |> is_list()

    content = List.first(response["result"]["content"])
    error_data = Jason.decode!(content["text"])
    assert error_data["error"] =~ "Unknown tool"
  end

  test "process_request handles invalid method" do
    request = %{"method" => "invalid_method"}
    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["error"]["code"] == -32601
    assert response["error"]["message"] == "Method not found"
  end

  test "process_request handles tools/call for get_system_status" do
    request = %{
      "method" => "tools/call",
      "params" => %{
        "name" => "get_system_status",
        "arguments" => %{}
      }
    }

    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["result"]["content"] |> is_list()
    assert length(response["result"]["content"]) == 1

    content = List.first(response["result"]["content"])
    assert content["type"] == "text"

    # Parse the JSON content to verify it's valid
    status_data = Jason.decode!(content["text"])
    assert is_map(status_data)
  end
end

defmodule SoupAndNutz.MCP.ServerDatabaseTest do
  use ExUnit.Case, async: false
  use SoupAndNutz.DataCase

  alias SoupAndNutz.MCP.Server

  @moduletag :integration

  test "process_request handles tools/call for list_conversations" do
    request = %{
      "method" => "tools/call",
      "params" => %{
        "name" => "list_conversations",
        "arguments" => %{}
      }
    }

    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["result"]["content"] |> is_list()

    content = List.first(response["result"]["content"])
    result = Jason.decode!(content["text"])

    # Should return a list (even if empty)
    assert is_list(result)
  end

  test "process_request handles tools/call for get_conversation" do
    request = %{
      "method" => "tools/call",
      "params" => %{
        "name" => "get_conversation",
        "arguments" => %{
          "conversation_id" => "nonexistent"
        }
      }
    }

    response = Server.process_request(request)

    assert response["jsonrpc"] == "2.0"
    assert response["result"]["content"] |> is_list()

    content = List.first(response["result"]["content"])
    result = Jason.decode!(content["text"])

    # Should return an error for nonexistent conversation
    assert result["error"] =~ "Conversation not found"
  end
end
