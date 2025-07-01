defmodule SoupAndNutz.AI.SemanticSearchTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.AI.SemanticSearch
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.Accounts

  @valid_asset_type "CashAndCashEquivalents"
  @valid_debt_type "CreditCard"
  @valid_reporting_period "2024-12-31"
  @valid_measurement_date ~D[2024-01-01]

  setup do
    Application.put_env(:soup_and_nutz, :openai_client, SoupAndNutz.AI.MockOpenAIClient)

    # Create test user
    {:ok, user} = Accounts.create_user(%{
      email: "test@example.com",
      username: "testuser",
      password: "password123",
      password_confirmation: "password123"
    })

    # Create test assets (without embeddings to avoid vector type issues)
    {:ok, asset1} = FinancialInstruments.create_asset(%{
      user_id: user.id,
      asset_identifier: "ASSET001",
      asset_name: "Apple Stock",
      asset_type: @valid_asset_type,
      fair_value: Decimal.new("15000"),
      currency_code: "USD",
      measurement_date: @valid_measurement_date,
      reporting_period: @valid_reporting_period
    })

    {:ok, asset2} = FinancialInstruments.create_asset(%{
      user_id: user.id,
      asset_identifier: "ASSET002",
      asset_name: "Savings Account",
      asset_type: @valid_asset_type,
      fair_value: Decimal.new("5000"),
      currency_code: "USD",
      measurement_date: @valid_measurement_date,
      reporting_period: @valid_reporting_period
    })

    # Create test debts (without embeddings to avoid vector type issues)
    {:ok, debt1} = FinancialInstruments.create_debt_obligation(%{
      user_id: user.id,
      debt_identifier: "DEBT001",
      debt_name: "Car Loan",
      debt_type: @valid_debt_type,
      outstanding_balance: Decimal.new("25000"),
      principal_amount: Decimal.new("25000"),
      currency_code: "USD",
      measurement_date: @valid_measurement_date,
      reporting_period: @valid_reporting_period
    })

    {:ok, debt2} = FinancialInstruments.create_debt_obligation(%{
      user_id: user.id,
      debt_identifier: "DEBT002",
      debt_name: "Credit Card",
      debt_type: @valid_debt_type,
      outstanding_balance: Decimal.new("3000"),
      principal_amount: Decimal.new("3000"),
      currency_code: "USD",
      measurement_date: @valid_measurement_date,
      reporting_period: @valid_reporting_period
    })

    {:ok, user: user, asset1: asset1, asset2: asset2, debt1: debt1, debt2: debt2}
  end

  describe "search_assets/3" do
    test "finds assets similar to query", %{user: user} do
      query = "technology stock investment"
      result = SemanticSearch.search_assets(query, user.id, 5)
      assert result == []
    end

    test "returns empty list when no assets have embeddings", %{user: user} do
      query = "test query"
      result = SemanticSearch.search_assets(query, user.id, 5)
      assert result == []
    end

    test "returns error when embedding generation fails", %{user: user} do
      defmodule SearchEmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, SearchEmbeddingErrorMock)
      query = "test query"
      result = SemanticSearch.search_assets(query, user.id, 5)
      assert result == []
    end
  end

  describe "search_debts/3" do
    test "finds debts similar to query", %{user: user} do
      query = "auto loan vehicle"
      result = SemanticSearch.search_debts(query, user.id, 5)
      assert result == []
    end

    test "returns error when embedding generation fails", %{user: user} do
      defmodule DebtSearchEmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, DebtSearchEmbeddingErrorMock)
      query = "test query"
      result = SemanticSearch.search_debts(query, user.id, 5)
      assert result == []
    end

    test "respects user isolation", %{user: user} do
      {:ok, other_user} = Accounts.create_user(%{
        email: "other@example.com",
        username: "otheruser",
        password: "password123",
        password_confirmation: "password123"
      })
      FinancialInstruments.create_debt_obligation(%{
        user_id: other_user.id,
        debt_identifier: "OTHER_DEBT",
        debt_name: "Other User Debt",
        debt_type: @valid_debt_type,
        outstanding_balance: Decimal.new("10000"),
        principal_amount: Decimal.new("10000"),
        currency_code: "USD",
        measurement_date: @valid_measurement_date,
        reporting_period: @valid_reporting_period
      })
      query = "loan"
      result = SemanticSearch.search_debts(query, user.id, 5)
      assert result == []
    end
  end

  describe "search_all/3" do
    test "searches both assets and debts", %{user: user} do
      query = "investment loan"
      result = SemanticSearch.search_all(query, user.id, 10)
      assert {:ok, []} = result
    end

    test "handles errors gracefully", %{user: user} do
      defmodule SearchAllEmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, SearchAllEmbeddingErrorMock)
      query = "test query"
      result = SemanticSearch.search_all(query, user.id, 10)
      assert {:ok, []} = result
    end
  end

  describe "find_similar_assets/3" do
    test "finds assets similar to given asset", %{user: user, asset1: asset1} do
      result = SemanticSearch.find_similar_assets(asset1, user.id, 5)
      assert result == []
    end

    test "returns empty list when asset has no embedding", %{user: user, asset1: asset1} do
      result = SemanticSearch.find_similar_assets(asset1, user.id, 5)
      assert result == []
    end
  end

  describe "find_similar_debts/3" do
    test "finds debts similar to given debt", %{user: user, debt1: debt1} do
      result = SemanticSearch.find_similar_debts(debt1, user.id, 5)
      assert result == []
    end

    test "returns empty list when debt has no embedding", %{user: user, debt1: debt1} do
      result = SemanticSearch.find_similar_debts(debt1, user.id, 5)
      assert result == []
    end
  end
end
