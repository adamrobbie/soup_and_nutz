#!/usr/bin/env elixir

# Simple LangChain Features Test
# This script tests basic functionality

# Start the application
Application.ensure_all_started(:soup_and_nutz)

defmodule SimpleLangChainTest do
  def run_test do
    IO.puts("🧪 Simple LangChain Features Test")
    IO.puts("=" |> String.duplicate(40))

    # Test 1: Basic module loading
    test_module_loading()

    # Test 2: Financial Calculator
    test_financial_calculator()

    # Test 3: Prompt Manager
    test_prompt_manager()

    IO.puts("\n✅ Test completed!")
  end

  def test_module_loading do
    IO.puts("\n1. Testing module loading...")

    modules = [
      SoupAndNutz.AISystem.FinancialCalculator,
      SoupAndNutz.AISystem.PromptManager,
      SoupAndNutz.AISystem.FinancialRouter,
      SoupAndNutz.AISystem.FinancialDataExtractor,
      SoupAndNutz.AISystem.FinancialSummarizer
    ]

    Enum.each(modules, fn module ->
      case Code.ensure_loaded(module) do
        {:module, _} ->
          IO.puts("  ✅ #{module} loaded successfully")
        {:error, reason} ->
          IO.puts("  ❌ #{module} failed to load: #{reason}")
      end
    end)
  end

  def test_financial_calculator do
    IO.puts("\n2. Testing Financial Calculator...")

    try do
      # Test compound interest
      result = SoupAndNutz.AISystem.FinancialCalculator.calculate_compound_interest(10000, 7, 20)
      IO.puts("  ✅ Compound interest calculation: $#{Float.round(result.final_amount, 2)}")

      # Test loan payment
      loan_result = SoupAndNutz.AISystem.FinancialCalculator.calculate_loan_payment(300000, 4.5, 30)
      IO.puts("  ✅ Loan payment calculation: $#{Float.round(loan_result.monthly_payment, 2)}")

      # Test budget allocation
      budget = SoupAndNutz.AISystem.FinancialCalculator.calculate_budget_allocation(5000)
      IO.puts("  ✅ Budget allocation: $#{Float.round(budget.savings_20_percent, 2)} savings")

    rescue
      e ->
        IO.puts("  ❌ Financial Calculator test failed: #{inspect(e)}")
    end
  end

  def test_prompt_manager do
    IO.puts("\n3. Testing Prompt Manager...")

    try do
      question = "How should I budget my $5,000 monthly income?"
      context = %{user_income: 5000, current_expenses: 3000, savings_goal: 1000}

      case SoupAndNutz.AISystem.PromptManager.create_prompt(question, context) do
        {:ok, prompt} ->
          IO.puts("  ✅ Prompt created successfully")
          IO.puts("  Prompt length: #{String.length(prompt)} characters")
        {:error, reason} ->
          IO.puts("  ❌ Prompt creation failed: #{reason}")
      end

    rescue
      e ->
        IO.puts("  ❌ Prompt Manager test failed: #{inspect(e)}")
    end
  end
end

# Run the test
SimpleLangChainTest.run_test()
