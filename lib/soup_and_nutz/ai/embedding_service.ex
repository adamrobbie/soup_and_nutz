defmodule SoupAndNutz.AI.EmbeddingService do
  @moduledoc """
  Service for generating and storing embeddings for financial instruments.
  """

  alias SoupAndNutz.AI.OpenAIService


  @doc """
  Generates an embedding for an asset and returns it as a Vector.
  """
  def generate_asset_embedding(asset) do
    text = build_asset_text(asset)

    case OpenAIService.generate_embedding(text) do
      {:ok, embedding} ->
        {:ok, embedding}
      {:error, error} ->
        {:error, "Failed to generate asset embedding: #{inspect(error)}"}
    end
  end

  @doc """
  Generates an embedding for a debt obligation and returns it as a Vector.
  """
  def generate_debt_embedding(debt) do
    text = build_debt_text(debt)

    case OpenAIService.generate_embedding(text) do
      {:ok, embedding} ->
        {:ok, embedding}
      {:error, error} ->
        {:error, "Failed to generate debt embedding: #{inspect(error)}"}
    end
  end

  @doc """
  Updates an asset's embedding.
  """
  def update_asset_embedding(asset) do
    case generate_asset_embedding(asset) do
      {:ok, embedding} ->
        asset
        |> Ecto.Changeset.change(%{embedding: embedding})
        |> SoupAndNutz.Repo.update()
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Updates a debt obligation's embedding.
  """
  def update_debt_embedding(debt) do
    case generate_debt_embedding(debt) do
      {:ok, embedding} ->
        debt
        |> Ecto.Changeset.change(%{embedding: embedding})
        |> SoupAndNutz.Repo.update()
      {:error, error} ->
        {:error, error}
    end
  end

  # Private functions

  defp build_asset_text(asset) do
    """
    Asset: #{asset.asset_name}
    Type: #{asset.asset_type}
    Category: #{asset.asset_category || "N/A"}
    Fair Value: #{format_money(asset.fair_value, asset.currency_code)}
    Book Value: #{format_money(asset.book_value, asset.currency_code)}
    Description: #{asset.description || "N/A"}
    Location: #{asset.location || "N/A"}
    Custodian: #{asset.custodian || "N/A"}
    Risk Level: #{asset.risk_level || "N/A"}
    Liquidity: #{asset.liquidity_level || "N/A"}
    """
  end

  defp build_debt_text(debt) do
    """
    Debt: #{debt.debt_name}
    Type: #{debt.debt_type}
    Category: #{debt.debt_category || "N/A"}
    Principal: #{format_money(debt.principal_amount, debt.currency_code)}
    Outstanding Balance: #{format_money(debt.outstanding_balance, debt.currency_code)}
    Interest Rate: #{format_percentage(debt.interest_rate)}%
    Lender: #{debt.lender_name || "N/A"}
    Monthly Payment: #{format_money(debt.monthly_payment, debt.currency_code)}
    Description: #{debt.description || "N/A"}
    Risk Level: #{debt.risk_level || "N/A"}
    Priority: #{debt.priority_level || "N/A"}
    """
  end

  defp format_money(amount, currency) when is_struct(amount, Decimal) do
    "#{Decimal.to_string(amount)} #{currency}"
  end
  defp format_money(amount, currency) when is_number(amount) do
    "#{amount} #{currency}"
  end
  defp format_money(_, currency), do: "0 #{currency}"

  defp format_percentage(rate) when is_struct(rate, Decimal) do
    Decimal.to_string(rate)
  end
  defp format_percentage(rate) when is_number(rate) do
    to_string(rate)
  end
  defp format_percentage(_), do: "0"
end
