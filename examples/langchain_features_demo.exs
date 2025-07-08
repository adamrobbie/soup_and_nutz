#!/usr/bin/env elixir

# LangChain Features Demo for Financial Planning
# This script demonstrates various LangChain features in action

# Start the application
Application.ensure_all_started(:soup_and_nutz)

alias SoupAndNutz.AISystem.{
  FinancialRouter,
  FinancialCalculator,
  PromptManager
}

defmodule LangChainFeaturesDemo do
  @moduledoc """
  Demonstrates various LangChain features for financial planning workflows.
  """

  def run_demo do
    IO.puts("🚀 LangChain Features Demo for Financial Planning")
    IO.puts("=" |> String.duplicate(60))

    # Test routing
    demo_routing()

    # Test calculations
    demo_calculations()

    # Test prompt templates
    demo_prompt_templates()

    # Test integrated workflow
    demo_integrated_workflow()

    IO.puts("\n✅ Demo completed!")
  end

  def demo_routing do
    IO.puts("\n🛣️ 1. Routing Chain Demo")
    IO.puts("-" |> String.duplicate(40))

    queries = [
      "How should I budget my $5,000 monthly income?",
      "I have $20,000 in credit card debt. What's the best way to pay it off?",
      "Should I invest in stocks or bonds for retirement?",
      "How much should I save for retirement?",
      "What tax deductions can I claim this year?",
      "Do I need life insurance?"
    ]

    Enum.each(queries, fn query ->
      IO.puts("\nQuery: #{query}")
      case FinancialRouter.route_financial_query(query) do
        {:ok, route, confidence} ->
          IO.puts("  → Routed to: #{route} (confidence: #{Float.round(confidence, 2)})")
        {:error, reason} ->
          IO.puts("  ❌ Routing failed: #{reason}")
      end
    end)

    # Test tool routing
    IO.puts("\nRouting to specific tools...")
    tool_queries = [
      "Calculate my monthly mortgage payment for a $300,000 loan at 4.5% for 30 years",
      "How much will I save in interest if I pay off my credit card in 2 years vs 5 years?",
      "Calculate compound interest on $10,000 at 7% for 20 years"
    ]

    Enum.each(tool_queries, fn query ->
      IO.puts("\nTool Query: #{query}")
      case FinancialRouter.route_to_tools(query) do
        {:ok, tool, confidence} ->
          IO.puts("  → Use tool: #{tool} (confidence: #{Float.round(confidence, 2)})")
        {:error, reason} ->
          IO.puts("  ❌ Tool routing failed: #{reason}")
      end
    end)
  end

  def demo_calculations do
    IO.puts("\n🧮 2. Financial Calculator Demo")
    IO.puts("-" |> String.duplicate(40))

    # Test compound interest
    IO.puts("Compound Interest Calculation:")
    result = FinancialCalculator.calculate_compound_interest(10000, 7, 20)
    IO.puts("  $10,000 at 7% for 20 years = $#{Float.round(result.final_amount, 2)}")
    IO.puts("  Interest earned: $#{Float.round(result.interest_earned, 2)}")

    # Test loan payment
    IO.puts("\nLoan Payment Calculation:")
    loan_result = FinancialCalculator.calculate_loan_payment(300000, 4.5, 30)
    IO.puts("  $300,000 loan at 4.5% for 30 years")
    IO.puts("  Monthly payment: $#{Float.round(loan_result.monthly_payment, 2)}")
    IO.puts("  Total interest: $#{Float.round(loan_result.total_interest, 2)}")

    # Test retirement planning
    IO.puts("\nRetirement Planning:")
    retirement = FinancialCalculator.calculate_retirement_needs(35, 65, 85, 50000, 75000)
    IO.puts("  Current age: #{retirement.current_age}, Retirement age: #{retirement.retirement_age}")
    IO.puts("  Total needed: $#{Float.round(retirement.total_needed, 2)}")
    IO.puts("  Monthly savings needed: $#{Float.round(retirement.monthly_savings_needed, 2)}")

    # Test budget allocation
    IO.puts("\nBudget Allocation (50/30/20 rule):")
    budget = FinancialCalculator.calculate_budget_allocation(5000)
    IO.puts("  Monthly income: $#{budget.monthly_income}")
    IO.puts("  Needs (50%): $#{Float.round(budget.needs_50_percent, 2)}")
    IO.puts("  Wants (30%): $#{Float.round(budget.wants_30_percent, 2)}")
    IO.puts("  Savings (20%): $#{Float.round(budget.savings_20_percent, 2)}")

    # Test debt payoff strategies
    IO.puts("\nDebt Payoff Strategies:")
    debts = [
      %{balance: 15000, interest_rate: 18, monthly_payment: 300},
      %{balance: 50000, interest_rate: 6, monthly_payment: 500}
    ]
    strategies = FinancialCalculator.calculate_debt_payoff_strategies(debts, 1000)
    IO.puts("  Recommended strategy: #{strategies.recommendation}")
    IO.puts("  Snowball total interest: $#{Float.round(strategies.snowball_strategy.total_interest, 2)}")
    IO.puts("  Avalanche total interest: $#{Float.round(strategies.avalanche_strategy.total_interest, 2)}")
  end

  def demo_prompt_templates do
    IO.puts("\n📋 3. Prompt Templates Demo")
    IO.puts("-" |> String.duplicate(40))

    # Test different prompt templates
    scenarios = [
      {
        "Budget Analysis",
        "I spend $3,000/month but want to save more",
        %{user_income: 5000, current_expenses: 3000, savings_goal: 1000}
      },
      {
        "Debt Payoff",
        "I have $15,000 in credit card debt at 18% interest",
        %{debt_amount: 15000, interest_rate: 18, monthly_payment: 500}
      },
      {
        "Investment Advice",
        "I want to invest $10,000 for retirement",
        %{investment_amount: 10000, time_horizon: 25, risk_tolerance: "moderate"}
      }
    ]

    Enum.each(scenarios, fn {title, question, context} ->
      IO.puts("\n#{title}:")
      IO.puts("Question: #{question}")

      case PromptManager.create_prompt(question, context) do
        {:ok, prompt} ->
          IO.puts("Generated Prompt:")
          IO.puts(prompt)
        {:error, reason} ->
          IO.puts("❌ Failed to create prompt: #{reason}")
      end
    end)
  end

  def demo_integrated_workflow do
    IO.puts("\n🔄 4. Integrated Workflow Demo")
    IO.puts("-" |> String.duplicate(40))

    # Simulate a complete workflow
    user_query = "I make $80,000/year and have $30,000 in debt. How should I prioritize saving vs debt payoff?"

    IO.puts("User Query: #{user_query}")

    # Step 1: Route the query
    case FinancialRouter.route_financial_query(user_query) do
      {:ok, route, confidence} ->
        IO.puts("→ Routed to: #{route} (confidence: #{Float.round(confidence, 2)})")

        # Step 2: Perform calculations
        annual_income = 80000
        monthly_income = annual_income / 12
        total_debt = 30000

        # Calculate debt payoff strategies
        debts = [
          %{balance: total_debt, interest_rate: 15, monthly_payment: 500}  # Assume average 15% interest
        ]
        extra_payment = monthly_income * 0.2  # Assume 20% extra for debt payoff

        strategies = FinancialCalculator.calculate_debt_payoff_strategies(debts, extra_payment)
        IO.puts("→ Recommended strategy: #{strategies.recommendation}")

        # Step 3: Calculate budget allocation
        budget = FinancialCalculator.calculate_budget_allocation(monthly_income)
        IO.puts("→ Monthly budget breakdown:")
        IO.puts("  - Needs: $#{Float.round(budget.needs_50_percent, 2)}")
        IO.puts("  - Wants: $#{Float.round(budget.wants_30_percent, 2)}")
        IO.puts("  - Savings: $#{Float.round(budget.savings_20_percent, 2)}")

        # Step 4: Create a structured response using prompt templates
        context = %{
          user_income: monthly_income,
          debt_amount: total_debt,
          savings_goal: 10000,
          recommended_strategy: strategies.recommendation
        }

        case PromptManager.create_prompt(user_query, context) do
          {:ok, prompt} ->
            IO.puts("→ Generated structured prompt for response")
          {:error, _} ->
            IO.puts("→ Using fallback prompt")
        end

      {:error, reason} ->
        IO.puts("❌ Routing failed: #{reason}")
    end

    IO.puts("\nThis demonstrates how multiple LangChain features work together:")
    IO.puts("1. Routing → 2. Calculations → 3. Budget Analysis → 4. Prompt Templates")
  end
end

# Run the demo
LangChainFeaturesDemo.run_demo()
