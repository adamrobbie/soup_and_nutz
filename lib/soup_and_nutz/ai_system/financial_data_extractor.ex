defmodule SoupAndNutz.AISystem.FinancialDataExtractor do
  @moduledoc """
  Extracts structured financial data from user messages using LangChain's DataExtractionChain.

  This module can parse natural language descriptions of financial situations and extract
  structured data like income, expenses, debts, assets, etc.
  """

    alias LangChain.Chains.DataExtractionChain
  alias LangChain.Message
  alias SoupAndNutz.AISystem.ModelProvider

  @doc """
  Extracts financial data from a user message.
  """
  def extract_financial_data(message) do
    # Define the schema for financial data extraction
    schema = %{
      type: "object",
      properties: %{
        income: %{
          type: "object",
          properties: %{
            monthly_income: %{type: "number", description: "Monthly income amount"},
            income_source: %{type: "string", description: "Primary source of income"},
            additional_income: %{type: "number", description: "Additional monthly income"}
          }
        },
        expenses: %{
          type: "object",
          properties: %{
            housing: %{type: "number", description: "Monthly housing expenses"},
            transportation: %{type: "number", description: "Monthly transportation costs"},
            food: %{type: "number", description: "Monthly food expenses"},
            utilities: %{type: "number", description: "Monthly utility bills"},
            entertainment: %{type: "number", description: "Monthly entertainment expenses"},
            other_expenses: %{type: "number", description: "Other monthly expenses"}
          }
        },
        debt: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              type: %{type: "string", description: "Type of debt (credit card, loan, mortgage, etc.)"},
              balance: %{type: "number", description: "Current balance"},
              interest_rate: %{type: "number", description: "Interest rate percentage"},
              monthly_payment: %{type: "number", description: "Monthly payment amount"}
            }
          }
        },
        assets: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              type: %{type: "string", description: "Type of asset (savings, investments, property, etc.)"},
              value: %{type: "number", description: "Current value"},
              monthly_contribution: %{type: "number", description: "Monthly contribution if applicable"}
            }
          }
        },
        goals: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              goal: %{type: "string", description: "Financial goal description"},
              target_amount: %{type: "number", description: "Target amount for the goal"},
              timeline_years: %{type: "number", description: "Timeline in years"}
            }
          }
        },
        personal_info: %{
          type: "object",
          properties: %{
            age: %{type: "number", description: "Current age"},
            risk_tolerance: %{type: "string", description: "Risk tolerance level (low, medium, high)"},
            employment_status: %{type: "string", description: "Employment status"}
          }
        }
      }
    }

    # Use the correct DataExtractionChain API
    case ModelProvider.get_model() do
      {:ok, llm} ->
        case DataExtractionChain.run(llm, schema, message) do
          {:ok, result} ->
            # The result is a list, we want the first item
            case result do
              [data] -> {:ok, data}
              [] -> {:ok, %{}}
              _ -> {:ok, List.first(result)}
            end
          {:error, reason} ->
            {:error, "Failed to extract financial data: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts budget information specifically.
  """
  def extract_budget_data(message) do
    schema = %{
      type: "object",
      properties: %{
        income: %{
          type: "object",
          properties: %{
            total_monthly: %{type: "number", description: "Total monthly income"},
            sources: %{
              type: "array",
              items: %{
                type: "object",
                properties: %{
                  source: %{type: "string", description: "Income source"},
                  amount: %{type: "number", description: "Monthly amount"}
                }
              }
            }
          }
        },
        expenses: %{
          type: "object",
          properties: %{
            total_monthly: %{type: "number", description: "Total monthly expenses"},
            categories: %{
              type: "array",
              items: %{
                type: "object",
                properties: %{
                  category: %{type: "string", description: "Expense category"},
                  amount: %{type: "number", description: "Monthly amount"}
                }
              }
            }
          }
        },
        savings_rate: %{type: "number", description: "Percentage of income saved monthly"}
      }
    }

    case ModelProvider.get_model() do
      {:ok, llm} ->
        case DataExtractionChain.run(llm, schema, message) do
          {:ok, result} ->
            case result do
              [data] -> {:ok, data}
              [] -> {:ok, %{}}
              _ -> {:ok, List.first(result)}
            end
          {:error, reason} ->
            {:error, "Failed to extract budget data: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts debt information specifically.
  """
  def extract_debt_data(message) do
    schema = %{
      type: "object",
      properties: %{
        total_debt: %{type: "number", description: "Total debt amount"},
        monthly_payments: %{type: "number", description: "Total monthly debt payments"},
        debt_to_income_ratio: %{type: "number", description: "Debt-to-income ratio percentage"},
        debts: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              type: %{type: "string", description: "Type of debt"},
              balance: %{type: "number", description: "Current balance"},
              interest_rate: %{type: "number", description: "Interest rate"},
              monthly_payment: %{type: "number", description: "Monthly payment"},
              priority: %{type: "string", description: "Payoff priority (high, medium, low)"}
            }
          }
        }
      }
    }

    case ModelProvider.get_model() do
      {:ok, llm} ->
        case DataExtractionChain.run(llm, schema, message) do
          {:ok, result} ->
            case result do
              [data] -> {:ok, data}
              [] -> {:ok, %{}}
              _ -> {:ok, List.first(result)}
            end
          {:error, reason} ->
            {:error, "Failed to extract debt data: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

  @doc """
  Extracts investment preferences and goals.
  """
  def extract_investment_profile(message) do
    schema = %{
      type: "object",
      properties: %{
        risk_tolerance: %{type: "string", description: "Risk tolerance level"},
        investment_timeline: %{type: "number", description: "Investment timeline in years"},
        investment_goals: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              goal: %{type: "string", description: "Investment goal"},
              target_amount: %{type: "number", description: "Target amount"},
              timeline: %{type: "number", description: "Timeline in years"}
            }
          }
        },
        current_investments: %{
          type: "array",
          items: %{
            type: "object",
            properties: %{
              type: %{type: "string", description: "Investment type"},
              value: %{type: "number", description: "Current value"},
              allocation: %{type: "number", description: "Percentage allocation"}
            }
          }
        }
      }
    }

    case ModelProvider.get_model() do
      {:ok, llm} ->
        case DataExtractionChain.run(llm, schema, message) do
          {:ok, result} ->
            case result do
              [data] -> {:ok, data}
              [] -> {:ok, %{}}
              _ -> {:ok, List.first(result)}
            end
          {:error, reason} ->
            {:error, "Failed to extract investment profile: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end
end
