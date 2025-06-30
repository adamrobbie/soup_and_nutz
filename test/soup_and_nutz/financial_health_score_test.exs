defmodule SoupAndNutz.FinancialHealthScoreTest do
  use SoupAndNutz.DataCase

  alias SoupAndNutz.FinancialHealthScore
  alias Decimal, as: D

  describe "calculate_health_score/2" do
    test "returns a complete health score structure" do
      user_id = 1
      currency = "USD"

      result = FinancialHealthScore.calculate_health_score(user_id, currency)

      assert is_map(result)
      assert Map.has_key?(result, :overall_score)
      assert Map.has_key?(result, :metrics)
      assert Map.has_key?(result, :recommendations)
      assert Map.has_key?(result, :calculated_at)

      # Check metrics structure
      metrics = result.metrics
      assert Map.has_key?(metrics, :savings_rate)
      assert Map.has_key?(metrics, :debt_to_income)
      assert Map.has_key?(metrics, :emergency_fund)
      assert Map.has_key?(metrics, :investment_diversification)
      assert Map.has_key?(metrics, :net_worth_trend)

      # Check that overall score is between 0 and 100
      assert result.overall_score >= 0
      assert result.overall_score <= 100
    end
  end

  describe "calculate_savings_rate/2" do
    test "calculates savings rate correctly" do
      cash_flows = [
        %{
          cash_flow_type: "Income",
          reporting_period: "2024-01",
          currency_code: "USD",
          is_active: true,
          amount: D.new("5000")
        },
        %{
          cash_flow_type: "Expense",
          reporting_period: "2024-01",
          currency_code: "USD",
          is_active: true,
          amount: D.new("4000")
        }
      ]

      result = FinancialHealthScore.calculate_savings_rate(cash_flows, "USD")

      assert result.score == 100
      assert D.eq?(result.percentage, D.new("20"))
    end

    test "handles zero income" do
      cash_flows = [
        %{
          cash_flow_type: "Expense",
          reporting_period: "2024-01",
          currency_code: "USD",
          is_active: true,
          amount: D.new("1000")
        }
      ]

      result = FinancialHealthScore.calculate_savings_rate(cash_flows, "USD")

      assert result.score == 0
      assert D.eq?(result.percentage, D.new("0"))
    end
  end

  describe "calculate_debt_to_income_ratio/3" do
    test "calculates debt-to-income ratio correctly" do
      debts = [
        %{
          currency_code: "USD",
          monthly_payment: D.new("500")
        }
      ]

      cash_flows = [
        %{
          cash_flow_type: "Income",
          reporting_period: "2024-01",
          currency_code: "USD",
          is_active: true,
          amount: D.new("5000")
        }
      ]

      result = FinancialHealthScore.calculate_debt_to_income_ratio(debts, cash_flows, "USD")

      assert result.score == 100  # 10% debt-to-income should be excellent
      assert D.eq?(result.ratio, D.new("10"))
      assert D.eq?(result.monthly_debt_payments, D.new("500"))
      assert D.eq?(result.monthly_income, D.new("5000"))
    end
  end

  describe "calculate_emergency_fund_adequacy/3" do
    test "calculates emergency fund adequacy correctly" do
      assets = [
        %{
          asset_type: "Savings",
          is_active: true,
          currency_code: "USD",
          fair_value: D.new("12000")
        }
      ]

      cash_flows = [
        %{
          cash_flow_type: "Expense",
          reporting_period: "2024-01",
          currency_code: "USD",
          is_active: true,
          amount: D.new("2000")
        }
      ]

      result = FinancialHealthScore.calculate_emergency_fund_adequacy(assets, cash_flows, "USD")

      assert result.score == 100  # 6 months of expenses should be excellent
      assert D.eq?(result.months_of_expenses, D.new("6"))
      assert D.eq?(result.liquid_assets, D.new("12000"))
      assert D.eq?(result.monthly_expenses, D.new("2000"))
    end
  end

  describe "calculate_investment_diversification/2" do
    test "calculates diversification score correctly" do
      assets = [
        %{
          asset_type: "Investment",
          is_active: true,
          currency_code: "USD",
          asset_category: "Stocks",
          fair_value: D.new("10000")
        },
        %{
          asset_type: "Investment",
          is_active: true,
          currency_code: "USD",
          asset_category: "Bonds",
          fair_value: D.new("5000")
        },
        %{
          asset_type: "Investment",
          is_active: true,
          currency_code: "USD",
          asset_category: "RealEstate",
          fair_value: D.new("15000")
        }
      ]

      result = FinancialHealthScore.calculate_investment_diversification(assets, "USD")

      assert result.score == 70  # 3 categories should be good
      assert D.eq?(result.diversification_score, D.new("3"))
      assert result.asset_categories == 3
      assert D.eq?(result.total_investment_value, D.new("30000"))
    end

    test "handles no investment assets" do
      assets = []

      result = FinancialHealthScore.calculate_investment_diversification(assets, "USD")

      assert result.score == 0
      assert D.eq?(result.total_investment_value, D.new("0"))
    end
  end

  describe "calculate_net_worth_trend/3" do
    test "calculates net worth trend correctly" do
      assets = [
        %{
          currency_code: "USD",
          fair_value: D.new("100000")
        }
      ]

      debts = [
        %{
          currency_code: "USD",
          outstanding_balance: D.new("30000")
        }
      ]

      result = FinancialHealthScore.calculate_net_worth_trend(assets, debts, "USD")

      assert result.score == 100  # Positive net worth should be excellent
      assert D.eq?(result.net_worth, D.new("70000"))
      assert D.eq?(result.total_assets, D.new("100000"))
      assert D.eq?(result.total_debts, D.new("30000"))
    end
  end

  describe "calculate_overall_score/1" do
    test "calculates weighted average correctly" do
      metric_weights = [
        {100, 25},
        {80, 25},
        {60, 20},
        {40, 15},
        {20, 15}
      ]

      result = FinancialHealthScore.calculate_overall_score(metric_weights)

      # Expected: (100*25 + 80*25 + 60*20 + 40*15 + 20*15) / 100 = 70
      assert result == 70
    end
  end

  describe "generate_recommendations/1" do
    test "generates recommendations for poor scores" do
      metrics = %{
        savings_rate: %{score: 25},
        debt_to_income: %{score: 30},
        emergency_fund: %{score: 20},
        investment_diversification: %{score: 15},
        net_worth_trend: %{score: 40}
      }

      recommendations = FinancialHealthScore.generate_recommendations(metrics)

      assert is_list(recommendations)
      assert length(recommendations) > 0
      assert Enum.any?(recommendations, &String.contains?(&1, "savings rate"))
      assert Enum.any?(recommendations, &String.contains?(&1, "debt"))
      assert Enum.any?(recommendations, &String.contains?(&1, "emergency fund"))
    end

    test "generates positive reinforcement for good scores" do
      metrics = %{
        savings_rate: %{score: 85},
        debt_to_income: %{score: 90},
        emergency_fund: %{score: 80},
        investment_diversification: %{score: 75},
        net_worth_trend: %{score: 85}
      }

      recommendations = FinancialHealthScore.generate_recommendations(metrics)

      assert is_list(recommendations)
      assert Enum.any?(recommendations, &String.contains?(&1, "Great job"))
    end
  end
end
