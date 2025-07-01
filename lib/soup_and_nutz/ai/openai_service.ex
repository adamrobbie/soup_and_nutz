defmodule SoupAndNutz.AI.OpenAIService do
  @moduledoc """
  Service for interacting with OpenAI API for natural language processing
  and financial data interpretation.
  """

  def openai_client do
    Application.get_env(:soup_and_nutz, :openai_client, OpenAI)
  end

  @doc """
  Processes natural language input and extracts structured financial data.
  """
  def process_natural_language_input(user_input, _user_id) do
    prompt = build_extraction_prompt(user_input)

    case apply(openai_client(), :chat_completion, [
      [
        model: "gpt-4",
        messages: [
          %{
            role: "system",
            content: """
            You are a financial data assistant that helps users create assets and debt obligations through natural language.
            You must respond with valid JSON that matches the expected schema.
            """
          },
          %{
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.1
      ]
    ]) do
      {:ok, response} ->
        parse_ai_response(response)
      {:error, error} ->
        {:error, "AI processing failed: #{inspect(error)}"}
    end
  end

  @doc """
  Generates embeddings for text using OpenAI's embedding API.
  """
  def generate_embedding(text) do
    case apply(openai_client(), :embeddings, [
      [
        model: "text-embedding-3-small",
        input: text
      ]
    ]) do
      {:ok, response} ->
        case response.data do
          [%{embedding: embedding} | _] -> {:ok, embedding}
          _ -> {:error, "No embedding generated"}
        end
      {:error, error} ->
        {:error, "Embedding generation failed: #{inspect(error)}"}
    end
  end

  @doc """
  Validates and suggests improvements for financial data.
  """
  def validate_financial_data(data, data_type) do
    prompt = build_validation_prompt(data, data_type)

    case apply(openai_client(), :chat_completion, [
      [
        model: "gpt-4",
        messages: [
          %{
            role: "system",
            content: """
            You are a financial data validator. Review the provided data and suggest improvements.
            Respond with JSON containing validation results and suggestions.
            """
          },
          %{
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.1
      ]
    ]) do
      {:ok, response} ->
        parse_validation_response(response)
      {:error, error} ->
        {:error, "Validation failed: #{inspect(error)}"}
    end
  end

  # Private functions

  defp build_extraction_prompt(user_input) do
    """
    Extract financial data from this user input: "#{user_input}"

    Determine if this is an asset or debt obligation and extract the relevant fields.

    For assets, extract:
    - asset_name: Human-readable name
    - asset_type: One of [CashAndCashEquivalents, MarketableSecurities, AccountsReceivable, Inventory, PrepaidExpenses, PropertyPlantAndEquipment, IntangibleAssets, InvestmentSecurities, RealEstate, Vehicles, Collectibles, Goodwill, DeferredTaxAssets, RestrictedCash, DerivativeInstruments, OtherAssets]
    - asset_category: Sub-category
    - fair_value: Numeric value
    - currency_code: ISO currency code (default USD)
    - description: Optional description
    - location: Optional location
    - custodian: Optional custodian

    For debt obligations, extract:
    - debt_name: Human-readable name
    - debt_type: One of [ShortTermDebt, LongTermDebt, Mortgage, CreditCard, StudentLoan, AutoLoan, PersonalLoan, BusinessLoan, LineOfCredit, Bond, LeaseObligation, AccountsPayable, AccruedExpenses, DeferredRevenue, PensionObligations, OtherDebt]
    - debt_category: Sub-category
    - principal_amount: Original loan amount
    - outstanding_balance: Current balance
    - interest_rate: Annual percentage rate
    - currency_code: ISO currency code (default USD)
    - lender_name: Name of lender
    - monthly_payment: Monthly payment amount
    - description: Optional description

    Respond with JSON in this format:
    {
      "type": "asset" or "debt",
      "data": { ... extracted fields ... },
      "confidence": 0.0-1.0,
      "missing_fields": ["field1", "field2"],
      "suggestions": ["suggestion1", "suggestion2"]
    }
    """
  end

  defp build_validation_prompt(data, data_type) do
    """
    Validate this #{data_type} data: #{Jason.encode!(data)}

    Check for:
    - Required fields
    - Data type consistency
    - Reasonable value ranges
    - Business logic violations

    Respond with JSON:
    {
      "is_valid": true/false,
      "errors": ["error1", "error2"],
      "warnings": ["warning1", "warning2"],
      "suggestions": ["suggestion1", "suggestion2"]
    }
    """
  end

  defp parse_ai_response(response) do
    case response.choices do
      [%{message: %{content: content}} | _] ->
        case Jason.decode(content) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, _} -> {:error, "Invalid JSON response from AI"}
        end
      _ ->
        {:error, "No response content from AI"}
    end
  end

  defp parse_validation_response(response) do
    case response.choices do
      [%{message: %{content: content}} | _] ->
        case Jason.decode(content) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, _} -> {:error, "Invalid JSON response from AI"}
        end
      _ ->
        {:error, "No response content from AI"}
    end
  end
end
