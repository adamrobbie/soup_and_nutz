defmodule SoupAndNutz.AI.ConversationMemoryTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.AI.ConversationMemory
  alias SoupAndNutz.Accounts

  setup do
    # Create test user
    {:ok, user} = Accounts.create_user(%{
      email: "test@example.com",
      username: "testuser",
      password: "password123",
      password_confirmation: "password123"
    })

    {:ok, user: user}
  end

  describe "create_memory/1" do
    test "creates a conversation memory entry", %{user: user} do
      attrs = %{
        user_id: user.id,
        conversation_id: "conv123",
        message: "Add a $5000 car loan",
        response: "Car loan created successfully",
        extracted_data: %{"type" => "debt", "amount" => 5000},
        confidence: 0.95,
        action_taken: "debt_created",
        context_summary: "User created a car loan",
        entities: %{"amount" => 5000, "type" => "car_loan"}
      }

      result = ConversationMemory.create_memory(attrs)

      assert {:ok, memory} = result
      assert memory.user_id == user.id
      assert memory.conversation_id == "conv123"
      assert memory.message == "Add a $5000 car loan"
      assert memory.response == "Car loan created successfully"
      assert memory.confidence == 0.95
      assert memory.action_taken == "debt_created"
    end

    test "validates required fields", %{user: user} do
      # Missing required fields
      attrs = %{
        user_id: user.id,
        # Missing conversation_id, message
        response: "Test response"
      }

      result = ConversationMemory.create_memory(attrs)

      assert {:error, changeset} = result
      assert %{conversation_id: ["can't be blank"], message: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates confidence range", %{user: user} do
      attrs = %{
        user_id: user.id,
        conversation_id: "conv123",
        message: "Test message",
        confidence: 1.5  # Invalid: > 1.0
      }

      result = ConversationMemory.create_memory(attrs)

      assert {:error, changeset} = result
      assert %{confidence: ["must be less than or equal to 1"]} = errors_on(changeset)
    end

    test "validates action_taken values", %{user: user} do
      attrs = %{
        user_id: user.id,
        conversation_id: "conv123",
        message: "Test message",
        action_taken: "invalid_action"  # Invalid action
      }

      result = ConversationMemory.create_memory(attrs)

      assert {:error, changeset} = result
      assert %{action_taken: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "get_recent_context/2" do
    test "returns recent conversation memories for user", %{user: user} do
      now = DateTime.utc_now()
      {:ok, memory1} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "conv1",
        message: "First message",
        response: "First response"
      })
      {:ok, memory2} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "conv2",
        message: "Second message",
        response: "Second response"
      })
      {:ok, memory3} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "conv3",
        message: "Third message",
        response: "Third response"
      })

      # Update timestamps directly to guarantee order
      alias SoupAndNutz.Repo
      Repo.update_all(
        from(m in ConversationMemory, where: m.id == ^memory1.id),
        set: [inserted_at: DateTime.add(now, -30, :second), updated_at: DateTime.add(now, -30, :second)]
      )
      Repo.update_all(
        from(m in ConversationMemory, where: m.id == ^memory2.id),
        set: [inserted_at: DateTime.add(now, -20, :second), updated_at: DateTime.add(now, -20, :second)]
      )
      Repo.update_all(
        from(m in ConversationMemory, where: m.id == ^memory3.id),
        set: [inserted_at: DateTime.add(now, -10, :second), updated_at: DateTime.add(now, -10, :second)]
      )

      memories = ConversationMemory.get_recent_context(user.id, 2)

      assert length(memories) == 2
      # Check that we get the most recent memories (should be the last two created)
      memory_messages = Enum.map(memories, & &1.message)
      assert "Third message" in memory_messages
      assert "Second message" in memory_messages
      assert "First message" not in memory_messages
    end

    test "respects user isolation", %{user: user} do
      # Create another user
      {:ok, other_user} = Accounts.create_user(%{
        email: "other@example.com",
        username: "otheruser",
        password: "password123",
        password_confirmation: "password123"
      })

      # Create memory for other user
      {:ok, _other_memory} = ConversationMemory.create_memory(%{
        user_id: other_user.id,
        conversation_id: "other_conv",
        message: "Other user message",
        response: "Other response"
      })

      # Create memory for test user
      {:ok, _test_memory} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "test_conv",
        message: "Test user message",
        response: "Test response"
      })

      memories = ConversationMemory.get_recent_context(user.id, 10)

      assert length(memories) == 1
      assert Enum.at(memories, 0).user_id == user.id
    end

    test "returns empty list for user with no memories", %{user: user} do
      memories = ConversationMemory.get_recent_context(user.id, 10)

      assert memories == []
    end
  end

  describe "get_conversation_context/1" do
    test "returns all memories for a conversation", %{user: user} do
      conversation_id = "test_conv"

      # Create multiple memories for same conversation
      {:ok, _memory1} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: conversation_id,
        message: "First message",
        response: "First response"
      })

      {:ok, _memory2} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: conversation_id,
        message: "Second message",
        response: "Second response"
      })

      memories = ConversationMemory.get_conversation_context(conversation_id)

      assert length(memories) == 2
      assert Enum.all?(memories, fn memory -> memory.conversation_id == conversation_id end)
    end

    test "returns empty list for non-existent conversation" do
      memories = ConversationMemory.get_conversation_context("non_existent")

      assert memories == []
    end
  end

  describe "summarize_context/1" do
    test "summarizes conversation memories", %{user: _user} do
      memories = [
        %ConversationMemory{
          message: "Add a car loan",
          action_taken: "debt_created",
          entities: %{"amount" => 5000}
        },
        %ConversationMemory{
          message: "Add an investment",
          action_taken: "asset_created",
          entities: %{"amount" => 10000}
        }
      ]

      summary = ConversationMemory.summarize_context(memories)

      assert is_binary(summary)
      assert String.contains?(summary, "Add a car loan")
      assert String.contains?(summary, "Add an investment")
      assert String.contains?(summary, "debt_created")
      assert String.contains?(summary, "asset_created")
    end

    test "handles empty memories list" do
      summary = ConversationMemory.summarize_context([])

      assert summary == ""
    end
  end

  describe "extract_entities/1" do
    test "extracts entities from conversation memories", %{user: _user} do
      memories = [
        %ConversationMemory{
          entities: %{"amount" => 5000, "type" => "car_loan"}
        },
        %ConversationMemory{
          entities: %{"amount" => 10000, "type" => "investment"}
        },
        %ConversationMemory{
          entities: %{"amount" => 5000, "type" => "car_loan"}  # Duplicate
        }
      ]

      entities = ConversationMemory.extract_entities(memories)

      assert entities["amount"] == [5000, 10000]
      assert entities["type"] == ["car_loan", "investment"]
    end

    test "handles memories with nil entities", %{user: _user} do
      memories = [
        %ConversationMemory{entities: nil},
        %ConversationMemory{entities: %{"amount" => 5000}}
      ]

      entities = ConversationMemory.extract_entities(memories)

      assert entities["amount"] == [5000]
    end
  end

  describe "generate_conversation_id/0" do
    test "generates unique conversation IDs" do
      id1 = ConversationMemory.generate_conversation_id()
      id2 = ConversationMemory.generate_conversation_id()

      assert id1 != id2
      assert is_binary(id1)
      assert is_binary(id2)
      assert String.length(id1) == 32  # 16 bytes = 32 hex chars
    end
  end

  describe "cleanup_old_memories/0" do
    test "removes memories older than 30 days", %{user: user} do
      # Create old memory (31 days ago)
      old_date = DateTime.utc_now() |> DateTime.add(-31 * 24 * 60 * 60, :second)

      {:ok, old_memory} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "old_conv",
        message: "Old message",
        response: "Old response"
      })

      # Manually update the inserted_at timestamp
      Repo.update_all(
        from(m in ConversationMemory, where: m.id == ^old_memory.id),
        set: [inserted_at: old_date]
      )

      # Create recent memory
      {:ok, recent_memory} = ConversationMemory.create_memory(%{
        user_id: user.id,
        conversation_id: "recent_conv",
        message: "Recent message",
        response: "Recent response"
      })

      # Run cleanup
      {deleted_count, _} = ConversationMemory.cleanup_old_memories()

      assert deleted_count > 0

      # Verify old memory is gone
      assert Repo.get(ConversationMemory, old_memory.id) == nil

      # Verify recent memory still exists
      assert Repo.get(ConversationMemory, recent_memory.id) != nil
    end
  end
end
