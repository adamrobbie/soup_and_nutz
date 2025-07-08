defmodule SoupAndNutz.AISystem.FinancialDataExtractorTest do
  use ExUnit.Case, async: true
  alias SoupAndNutz.AISystem.FinancialDataExtractor

  describe "extract_financial_data/1" do
    test "extracts comprehensive financial data from user message" do
      message = """
      I'm 35 years old and make $75,000 annually. My monthly expenses are about $3,500 including
      $1,200 for rent, $400 for food, $300 for utilities, and $200 for entertainment. I have
      $15,000 in credit card debt at 18% interest and $200,000 in student loans at 6% interest.
      I have $25,000 in savings and $50,000 in a 401k. My goal is to buy a house in 5 years
      and save $100,000 for a down payment. I'm moderately risk-tolerant.
      """

      case FinancialDataExtractor.extract_financial_data(message) do
        {:ok, data} ->
          # Verify income data
          assert data.income.monthly_income == 6250.0
          assert data.income.income_source == "employment"

          # Verify expenses
          assert data.expenses.housing == 1200.0
          assert data.expenses.food == 400.0
          assert data.expenses.utilities == 300.0
          assert data.expenses.entertainment == 200.0

          # Verify debt
          assert length(data.debt) == 2
          credit_card = Enum.find(data.debt, fn debt -> debt.type == "credit card" end)
          assert credit_card.balance == 15000.0
          assert credit_card.interest_rate == 18.0

          # Verify assets
          assert length(data.assets) == 2
          savings = Enum.find(data.assets, fn asset -> asset.type == "savings" end)
          assert savings.value == 25000.0

          # Verify goals
          assert length(data.goals) == 1
          goal = List.first(data.goals)
          assert goal.goal == "buy a house"
          assert goal.target_amount == 100000.0
          assert goal.timeline_years == 5.0

          # Verify personal info
          assert data.personal_info.age == 35.0
          assert data.personal_info.risk_tolerance == "moderate"

        {:error, reason} ->
          flunk("Failed to extract financial data: #{reason}")
      end
    end

    test "handles partial financial information" do
      message = "I make $50,000 a year and have some credit card debt."

      case FinancialDataExtractor.extract_financial_data(message) do
        {:ok, data} ->
          assert data.income.monthly_income == 4166.67
          assert data.income.income_source == "employment"
          assert data.expenses.housing == nil
          assert data.personal_info.age == nil

        {:error, reason} ->
          flunk("Failed to extract partial data: #{reason}")
      end
    end

    test "handles empty or invalid messages" do
      assert {:error, _} = FinancialDataExtractor.extract_financial_data("")
      assert {:error, _} = FinancialDataExtractor.extract_financial_data("Hello")
    end
  end

  describe "extract_budget_data/1" do
    test "extracts budget information with income and expenses" do
      message = """
      I make $6,000 per month. My expenses are: rent $1,500, food $600,
      transportation $300, utilities $200, and entertainment $400.
      I save about $1,000 per month.
      """

      case FinancialDataExtractor.extract_budget_data(message) do
        {:ok, data} ->
          assert data.income.total_monthly == 6000.0
          assert data.expenses.total_monthly == 3000.0
          assert data.savings_rate == 16.67

          # Verify income sources
          assert length(data.income.sources) == 1
          source = List.first(data.income.sources)
          assert source.source == "employment"
          assert source.amount == 6000.0

          # Verify expense categories
          assert length(data.expenses.categories) == 5
          rent = Enum.find(data.expenses.categories, fn cat -> cat.category == "rent" end)
          assert rent.amount == 1500.0

        {:error, reason} ->
          flunk("Failed to extract budget data: #{reason}")
      end
    end
  end

  describe "extract_debt_data/1" do
    test "extracts debt information with calculations" do
      message = """
      I have $20,000 in credit card debt at 22% interest with $400 monthly payments,
      and $50,000 in student loans at 5% interest with $500 monthly payments.
      My monthly income is $5,000.
      """

      case FinancialDataExtractor.extract_debt_data(message) do
        {:ok, data} ->
          assert data.total_debt == 70000.0
          assert data.monthly_payments == 900.0
          assert data.debt_to_income_ratio == 18.0

          # Verify debts
          assert length(data.debts) == 2
          credit_card = Enum.find(data.debts, fn debt -> debt.type == "credit card" end)
          assert credit_card.balance == 20000.0
          assert credit_card.interest_rate == 22.0
          assert credit_card.monthly_payment == 400.0
          assert credit_card.priority == "high"

        {:error, reason} ->
          flunk("Failed to extract debt data: #{reason}")
      end
    end
  end

  describe "extract_investment_profile/1" do
    test "extracts investment preferences and goals" do
      message = """
      I'm 30 years old with a moderate risk tolerance. I want to retire at 65.
      My investment goals are: save $1,000,000 for retirement and $50,000 for a house down payment.
      I currently have $25,000 in a 401k and $10,000 in a Roth IRA.
      """

      case FinancialDataExtractor.extract_investment_profile(message) do
        {:ok, data} ->
          assert data.risk_tolerance == "moderate"
          assert data.investment_timeline == 35.0

          # Verify investment goals
          assert length(data.investment_goals) == 2
          retirement_goal = Enum.find(data.investment_goals, fn goal -> goal.goal == "retirement" end)
          assert retirement_goal.target_amount == 1000000.0
          assert retirement_goal.timeline == 35.0

          # Verify current investments
          assert length(data.current_investments) == 2
          ira = Enum.find(data.current_investments, fn inv -> inv.type == "Roth IRA" end)
          assert ira.value == 10000.0

        {:error, reason} ->
          flunk("Failed to extract investment profile: #{reason}")
      end
    end
  end
end
