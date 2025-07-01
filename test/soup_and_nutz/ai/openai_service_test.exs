defmodule SoupAndNutz.AI.OpenAIServiceTest do
  use ExUnit.Case, async: true
  alias SoupAndNutz.AI.OpenAIService

  defmodule ValidationMock do
    def chat_completion(_opts) do
      {:ok, %{choices: [%{message: %{content: ~s({"is_valid": true})}}]}}
    end
  end

  setup do
    Application.put_env(:soup_and_nutz, :openai_client, SoupAndNutz.AI.MockOpenAIClient)
    :ok
  end

  describe "process_natural_language_input/2" do
    test "processes asset creation prompt successfully" do
      prompt = "Add a $10,000 investment in Apple stock"
      user_id = 1

      result = OpenAIService.process_natural_language_input(prompt, user_id)

      assert {:ok, response} = result
      assert response["type"] == "asset"
      assert response["data"]["asset_name"] == "Test Asset"
      assert response["data"]["asset_type"] == "InvestmentSecurities"
      assert response["data"]["fair_value"] == "10000"
      assert response["data"]["currency_code"] == "USD"
      assert response["confidence"] == 0.95
    end

    test "handles OpenAI API errors gracefully" do
      defmodule ErrorMock do
        def chat_completion(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, ErrorMock)

      prompt = "Add a $10,000 investment"
      user_id = 1

      result = OpenAIService.process_natural_language_input(prompt, user_id)

      assert {:error, _message} = result
    end

    test "handles invalid JSON response" do
      defmodule InvalidJSONMock do
        def chat_completion(_opts), do: {:ok, %{choices: [%{message: %{content: "Invalid JSON response"}}]}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, InvalidJSONMock)

      prompt = "Add a $10,000 investment"
      user_id = 1

      result = OpenAIService.process_natural_language_input(prompt, user_id)

      assert {:error, "Invalid JSON response from AI"} = result
    end
  end

  describe "generate_embedding/1" do
    test "generates embedding successfully" do
      text = "Test text for embedding"

      result = OpenAIService.generate_embedding(text)

      assert {:ok, embedding} = result
      assert is_list(embedding)
      assert length(embedding) == 5
      assert Enum.all?(embedding, &is_float/1)
    end

    test "handles embedding API errors" do
      defmodule EmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, EmbeddingErrorMock)

      text = "Test text"

      result = OpenAIService.generate_embedding(text)

      assert {:error, _message} = result
    end

    test "handles empty embedding response" do
      defmodule EmptyEmbeddingMock do
        def embeddings(_opts), do: {:ok, %{data: []}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, EmptyEmbeddingMock)

      text = "Test text"

      result = OpenAIService.generate_embedding(text)

      assert {:error, "No embedding generated"} = result
    end
  end

  describe "validate_financial_data/2" do
    test "validates asset data successfully" do
      Application.put_env(:soup_and_nutz, :openai_client, ValidationMock)
      asset_data = %{
        "asset_name" => "Test Asset",
        "asset_type" => "InvestmentSecurities",
        "fair_value" => "10000"
      }
      result = OpenAIService.validate_financial_data(asset_data, "asset")
      assert {:ok, response} = result
      assert response["is_valid"] == true
    end

    test "validates debt data successfully" do
      Application.put_env(:soup_and_nutz, :openai_client, ValidationMock)
      debt_data = %{
        "debt_name" => "Test Debt",
        "debt_type" => "Loan",
        "outstanding_balance" => "5000"
      }
      result = OpenAIService.validate_financial_data(debt_data, "debt")
      assert {:ok, response} = result
      assert response["is_valid"] == true
    end
  end
end
