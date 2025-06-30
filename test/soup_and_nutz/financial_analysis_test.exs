defmodule SoupAndNutz.FinancialAnalysisTest do
  use SoupAndNutz.DataCase
  alias SoupAndNutz.FinancialAnalysis
  alias SoupAndNutz.FinancialInstrumentsFixtures
  alias SoupAndNutz.Factory

  setup do
    user = Factory.insert(:user)
    {:ok, user: user}
  end

  describe "calculate_net_worth/4" do
    test "returns correct net worth and projections", %{user: user} do
      period = "2024-Q1"
      currency = "USD"
      projection_months = 6

      _asset = FinancialInstrumentsFixtures.asset_fixture(%{fair_value: "10000.00", currency_code: currency, user_id: user.id, reporting_period: period})
      _debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{outstanding_balance: "5000.00", currency_code: currency, user_id: user.id, reporting_period: period})
      _cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1000.00", cash_flow_type: "Income", currency_code: currency, user_id: user.id, reporting_period: period})

      result = FinancialAnalysis.calculate_net_worth(user.id, period, currency, projection_months)
      assert result.current_net_worth == Decimal.new("5000.00")
      assert result.total_assets == Decimal.new("10000.00")
      assert result.total_debts == Decimal.new("5000.00")
      assert result.projection_months == projection_months
      assert Decimal.compare(result.projected_net_worth, result.current_net_worth) == :gt
    end
  end

  describe "generate_financial_health_report/3" do
    test "returns a comprehensive report with metrics and recommendations", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      FinancialInstrumentsFixtures.asset_fixture(%{fair_value: "20000.00", currency_code: currency, user_id: user.id, reporting_period: period, asset_category: "Savings"})
      FinancialInstrumentsFixtures.debt_obligation_fixture(%{outstanding_balance: "5000.00", currency_code: currency, user_id: user.id, reporting_period: period})
      FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "3000.00", cash_flow_type: "Income", currency_code: currency, user_id: user.id, reporting_period: period})
      FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1000.00", cash_flow_type: "Expense", currency_code: currency, user_id: user.id, reporting_period: period})

      report = FinancialAnalysis.generate_financial_health_report(user.id, period, currency)
      assert report.net_worth == Decimal.new("15000.00")
      assert report.total_assets == Decimal.new("20000.00")
      assert report.total_debts == Decimal.new("5000.00")
      assert report.monthly_income == Decimal.new("3000.00")
      assert report.monthly_expenses == Decimal.new("1000.00")
      assert report.net_monthly_cash_flow == Decimal.new("2000.00")
      assert is_list(report.recommendations)
    end
  end

  describe "analyze_cash_flow_impact/4" do
    test "analyzes cash flow impact and returns breakdown", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "2000.00", cash_flow_type: "Income", currency_code: currency, user_id: user.id, reporting_period: period, cash_flow_category: "Salary"})
      FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "500.00", cash_flow_type: "Expense", currency_code: currency, user_id: user.id, reporting_period: period, cash_flow_category: "Rent"})
      months = 3

      result = FinancialAnalysis.analyze_cash_flow_impact(user.id, period, currency, months)
      assert result.monthly_income == Decimal.new("2000.00")
      assert result.monthly_expenses == Decimal.new("500.00")
      assert result.monthly_net_cash_flow == Decimal.new("1500.00")
      assert result.analysis_months == months
      assert result.cumulative_impact == Decimal.new("9000.00")
      assert result.annual_impact == Decimal.new("18000.00")
      assert is_list(result.expense_breakdown)
      assert Enum.all?(result.expense_breakdown, fn {cat, val} -> is_binary(cat) and is_map(val) end)
    end
  end

  describe "calculate_financial_ratios/3" do
    test "returns a map of financial ratios", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      _savings_asset = FinancialInstrumentsFixtures.asset_fixture(%{fair_value: "15000.00", currency_code: currency, user_id: user.id, reporting_period: period, liquidity_level: "High", asset_type: "InvestmentSecurities", asset_category: "Savings"})
      _retirement_asset = FinancialInstrumentsFixtures.asset_fixture(%{fair_value: "12000.00", currency_code: currency, user_id: user.id, reporting_period: period, liquidity_level: "High", asset_type: "InvestmentSecurities", asset_category: "Retirement"})
      _debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{outstanding_balance: "3000.00", currency_code: currency, user_id: user.id, reporting_period: period})
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "4000.00", cash_flow_type: "Income", currency_code: currency, user_id: user.id, reporting_period: period})
      _expense = FinancialInstrumentsFixtures.cash_flow_fixture(%{amount: "1000.00", cash_flow_type: "Expense", currency_code: currency, user_id: user.id, reporting_period: period})

      ratios = FinancialAnalysis.calculate_financial_ratios(user.id, period, currency)
      assert is_map(ratios)
      cmp_current_ratio = Decimal.compare(ratios.current_ratio, Decimal.new("4"))
      cmp_savings_rate = Decimal.compare(ratios.savings_rate, Decimal.new("75"))
      cmp_emergency_fund_ratio = Decimal.compare(ratios.emergency_fund_ratio, Decimal.new("12"))
      cmp_investment_to_income_ratio = Decimal.compare(ratios.investment_to_income_ratio, Decimal.new("25"))
      cmp_retirement_savings_ratio = Decimal.compare(ratios.retirement_savings_ratio, Decimal.new("25"))
      assert cmp_current_ratio in [:eq, :gt]
      assert cmp_savings_rate in [:eq, :gt]
      assert cmp_emergency_fund_ratio in [:eq, :gt]
      assert cmp_investment_to_income_ratio in [:eq, :gt]
      assert cmp_retirement_savings_ratio in [:eq, :gt]
    end
  end
end
