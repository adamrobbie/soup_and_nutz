defmodule SoupAndNutz.AI.EmbeddingServiceTest do
  use ExUnit.Case, async: true
  alias SoupAndNutz.AI.EmbeddingService
  alias SoupAndNutz.FinancialInstruments.Asset
  alias SoupAndNutz.FinancialInstruments.DebtObligation

  setup do
    Application.put_env(:soup_and_nutz, :openai_client, SoupAndNutz.AI.MockOpenAIClient)
    :ok
  end

  describe "generate_asset_embedding/1" do
    test "generates embedding for asset with all fields" do
      asset = %Asset{
        asset_name: "Apple Stock",
        asset_type: "InvestmentSecurities",
        asset_category: "Technology",
        fair_value: Decimal.new("15000"),
        book_value: Decimal.new("12000"),
        currency_code: "USD",
        measurement_date: ~D[2023-01-15],
        description: "Technology stock investment",
        location: "Brokerage Account",
        custodian: "Fidelity",
        risk_level: "Medium",
        liquidity_level: "High"
      }

      result = EmbeddingService.generate_asset_embedding(asset)

      assert {:ok, embedding} = result
      assert is_list(embedding)
      assert length(embedding) == 5
      assert Enum.all?(embedding, &is_float/1)
    end

    test "generates embedding for asset with minimal fields" do
      asset = %Asset{
        asset_name: "Simple Asset",
        asset_type: "Cash",
        fair_value: Decimal.new("1000"),
        currency_code: "USD"
      }

      result = EmbeddingService.generate_asset_embedding(asset)

      assert {:ok, embedding} = result
      assert is_list(embedding)
      assert length(embedding) == 5
    end

    test "handles embedding generation errors" do
      defmodule AssetEmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, AssetEmbeddingErrorMock)

      asset = %Asset{
        asset_name: "Test Asset",
        asset_type: "InvestmentSecurities",
        fair_value: Decimal.new("1000"),
        currency_code: "USD"
      }

      result = EmbeddingService.generate_asset_embedding(asset)

      assert {:error, _message} = result
    end
  end

  describe "generate_debt_embedding/1" do
    test "generates embedding for debt with all fields" do
      debt = %DebtObligation{
        debt_name: "Car Loan",
        debt_type: "AutoLoan",
        debt_category: "Vehicle",
        principal_amount: Decimal.new("25000"),
        outstanding_balance: Decimal.new("20000"),
        interest_rate: Decimal.new("5.5"),
        currency_code: "USD",
        measurement_date: ~D[2023-01-01],
        lender_name: "Bank of America",
        account_number: "123456789",
        maturity_date: ~D[2028-01-01],
        monthly_payment: Decimal.new("500"),
        description: "Auto loan for new car",
        collateral_description: "2023 Toyota Camry",
        risk_level: "Low"
      }

      result = EmbeddingService.generate_debt_embedding(debt)

      assert {:ok, embedding} = result
      assert is_list(embedding)
      assert length(embedding) == 5
      assert Enum.all?(embedding, &is_float/1)
    end

    test "generates embedding for debt with minimal fields" do
      debt = %DebtObligation{
        debt_name: "Simple Debt",
        debt_type: "PersonalLoan",
        principal_amount: Decimal.new("5000"),
        outstanding_balance: Decimal.new("5000"),
        currency_code: "USD"
      }

      result = EmbeddingService.generate_debt_embedding(debt)

      assert {:ok, embedding} = result
      assert is_list(embedding)
      assert length(embedding) == 5
    end

    test "handles embedding generation errors for debt" do
      defmodule DebtEmbeddingErrorMock do
        def embeddings(_opts), do: {:error, %{"error" => %{"message" => "API key not found"}}}
      end
      Application.put_env(:soup_and_nutz, :openai_client, DebtEmbeddingErrorMock)

      debt = %DebtObligation{
        debt_name: "Test Debt",
        debt_type: "PersonalLoan",
        principal_amount: Decimal.new("5000"),
        outstanding_balance: Decimal.new("5000"),
        currency_code: "USD"
      }

      result = EmbeddingService.generate_debt_embedding(debt)

      assert {:error, _message} = result
    end
  end

  describe "text formatting" do
    test "formats money values correctly" do
      asset = %Asset{
        asset_name: "Test Asset",
        asset_type: "InvestmentSecurities",
        fair_value: Decimal.new("12345.67"),
        currency_code: "USD"
      }

      result = EmbeddingService.generate_asset_embedding(asset)

      assert {:ok, _embedding} = result
    end

    test "handles nil values gracefully" do
      asset = %Asset{
        asset_name: "Test Asset",
        asset_type: "InvestmentSecurities",
        fair_value: Decimal.new("1000"),
        currency_code: "USD",
        description: nil,
        location: nil
      }

      result = EmbeddingService.generate_asset_embedding(asset)

      assert {:ok, _embedding} = result
    end

    test "formats percentage values correctly" do
      debt = %DebtObligation{
        debt_name: "Test Debt",
        debt_type: "PersonalLoan",
        principal_amount: Decimal.new("5000"),
        outstanding_balance: Decimal.new("5000"),
        currency_code: "USD",
        interest_rate: Decimal.new("5.25")  # 5.25%
      }

      result = EmbeddingService.generate_debt_embedding(debt)

      assert {:ok, _embedding} = result
    end
  end
end
