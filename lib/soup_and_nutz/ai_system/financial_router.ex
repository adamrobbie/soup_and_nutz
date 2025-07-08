defmodule SoupAndNutz.AISystem.FinancialRouter do
  @moduledoc """
  Routes user queries to appropriate financial specialists using LangChain's RoutingChain.

  This module can intelligently determine which type of financial advice or tool
  is most appropriate for a given user query.
  """

    alias LangChain.Chains.RoutingChain
  alias LangChain.Routing.PromptRoute
  alias LangChain.Message
  alias SoupAndNutz.AISystem.ModelProvider

  @doc """
  Routes a user query to the appropriate financial specialist.
  """
  def route_financial_query(message) do
    # For now, implement a simple keyword-based routing since RoutingChain requires PromptRoute structs
    # which need actual chain implementations

    specialists = [
      {"budget_specialist", ["budget", "spending", "expenses", "income", "save money", "cash flow", "savings"]},
      {"debt_specialist", ["debt", "loan", "credit card", "pay off", "snowball", "avalanche", "interest"]},
      {"investment_advisor", ["invest", "portfolio", "stocks", "bonds", "asset allocation", "risk tolerance", "retirement"]},
      {"tax_advisor", ["tax", "deduction", "refund", "filing", "irs", "withholding"]},
      {"insurance_specialist", ["insurance", "coverage", "policy", "premium", "deductible", "life insurance", "health insurance"]},
      {"retirement_planner", ["retirement", "401k", "ira", "social security", "pension", "nest egg"]},
      {"estate_planner", ["estate", "will", "trust", "inheritance", "legacy", "beneficiary"]},
      {"general_advisor", ["what is", "explain", "how does", "learn about", "understand", "basics"]}
    ]

    message_lower = String.downcase(message)

    # Find the best match
    {specialist, confidence} = Enum.reduce(specialists, {"general_advisor", 0.0}, fn {name, keywords}, {best, best_score} ->
      score = Enum.reduce(keywords, 0.0, fn keyword, acc ->
        if String.contains?(message_lower, keyword) do
          acc + 1.0
        else
          acc
        end
      end)

      if score > best_score do
        {name, score / length(keywords)}
      else
        {best, best_score}
      end
    end)

    {:ok, specialist, confidence}
  end

  @doc """
  Routes queries to specific financial tools or calculators.
  """
  def route_to_tools(message) do
    tools = [
      {"budget_calculator", ["calculate budget", "savings rate", "expense breakdown", "income vs expenses"]},
      {"debt_payoff_calculator", ["debt payoff", "snowball method", "avalanche method", "payoff timeline", "interest savings"]},
      {"investment_calculator", ["investment returns", "compound interest", "growth calculator", "portfolio value"]},
      {"retirement_calculator", ["retirement needs", "savings goal", "retirement age", "nest egg", "social security"]},
      {"mortgage_calculator", ["mortgage", "home loan", "monthly payment", "affordability", "down payment"]},
      {"tax_calculator", ["tax calculation", "deductions", "tax bracket", "withholding", "refund"]}
    ]

    message_lower = String.downcase(message)

    # Find the best match
    {tool, confidence} = Enum.reduce(tools, {"budget_calculator", 0.0}, fn {name, keywords}, {best, best_score} ->
      score = Enum.reduce(keywords, 0.0, fn keyword, acc ->
        if String.contains?(message_lower, keyword) do
          acc + 1.0
        else
          acc
        end
      end)

      if score > best_score do
        {name, score / length(keywords)}
      else
        {best, best_score}
      end
    end)

    {:ok, tool, confidence}
  end

  @doc """
  Routes queries to educational content or basic advice.
  """
  def route_educational_content(message) do
    content_types = [
      {"financial_basics", ["what is", "explain", "basics", "fundamentals", "terminology"]},
      {"investment_education", ["stocks", "bonds", "mutual funds", "etfs", "diversification", "risk"]},
      {"debt_education", ["credit score", "interest rates", "debt types", "credit cards", "loans"]},
      {"tax_education", ["tax brackets", "deductions", "credits", "filing", "withholding"]},
      {"retirement_education", ["401k", "ira", "social security", "pension", "retirement age"]}
    ]

    message_lower = String.downcase(message)

    # Find the best match
    {content_type, confidence} = Enum.reduce(content_types, {"financial_basics", 0.0}, fn {name, keywords}, {best, best_score} ->
      score = Enum.reduce(keywords, 0.0, fn keyword, acc ->
        if String.contains?(message_lower, keyword) do
          acc + 1.0
        else
          acc
        end
      end)

      if score > best_score do
        {name, score / length(keywords)}
      else
        {best, best_score}
      end
    end)

    {:ok, content_type, confidence}
  end
end
