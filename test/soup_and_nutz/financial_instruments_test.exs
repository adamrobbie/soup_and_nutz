defmodule SoupAndNutz.FinancialInstrumentsTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.Factory
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.{Asset, CashFlow, DebtObligation}
  alias SoupAndNutz.FinancialInstrumentsFixtures

  setup do
    user = Factory.insert(:user)
    {:ok, user: user}
  end

  describe "asset functions" do
    test "list_assets/0 returns all assets", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assets = FinancialInstruments.list_assets()
      assert Enum.any?(assets, &(&1.id == asset.id))
    end

    test "list_assets_by_user/1 returns assets for specific user", %{user: user} do
      asset1 = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      other_user = Factory.insert(:user)
      _asset2 = FinancialInstrumentsFixtures.asset_fixture(%{user_id: other_user.id})

      result = FinancialInstruments.list_assets_by_user(user.id)
      assert length(result) == 1
      assert List.first(result).id == asset1.id
    end

    test "get_asset!/1 returns the asset with given id", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assert FinancialInstruments.get_asset!(asset.id) == asset
    end

    test "get_asset_by_identifier/1 returns the asset with given identifier", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assert FinancialInstruments.get_asset_by_identifier(asset.asset_identifier) == asset
    end

    test "create_asset/1 with valid data creates an asset", %{user: user} do
      valid_attrs = %{
        asset_name: "Test Asset",
        asset_type: "InvestmentSecurities",
        asset_category: "Retirement",
        fair_value: "10000.00",
        currency_code: "USD",
        user_id: user.id,
        reporting_period: "2024-Q1",
        asset_identifier: "TEST_ASSET_001",
        measurement_date: ~D[2024-01-15],
        xbrl_concept_identifier: "us-gaap:InvestmentSecurities",
        xbrl_context_ref: "test-context"
      }

      assert {:ok, asset} = FinancialInstruments.create_asset(valid_attrs)
      assert asset.asset_name == "Test Asset"
      assert asset.fair_value == Decimal.new("10000.00")
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.create_asset(%{asset_name: nil})
    end

    test "update_asset/2 with valid data updates the asset", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      update_attrs = %{asset_name: "Updated Asset"}

      assert {:ok, %Asset{} = updated_asset} = FinancialInstruments.update_asset(asset, update_attrs)
      assert updated_asset.asset_name == "Updated Asset"
    end

    test "update_asset/2 with invalid data returns error changeset", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.update_asset(asset, %{asset_name: nil})
    end

    test "delete_asset/1 deletes the asset", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assert {:ok, %Asset{}} = FinancialInstruments.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> FinancialInstruments.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset", %{user: user} do
      asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = FinancialInstruments.change_asset(asset)
    end
  end

  describe "debt obligation functions" do
    test "list_debt_obligations/0 returns all debt obligations", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      result = FinancialInstruments.list_debt_obligations()
      assert Enum.any?(result, &(&1.id == debt.id))
    end

    test "list_debt_obligations_by_user/1 returns debts for specific user", %{user: user} do
      debt1 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      other_user = Factory.insert(:user)
      _debt2 = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: other_user.id})

      result = FinancialInstruments.list_debt_obligations_by_user(user.id)
      assert length(result) == 1
      assert List.first(result).id == debt1.id
    end

    test "get_debt_obligation!/1 returns the debt obligation with given id", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      result = FinancialInstruments.get_debt_obligation!(debt.id)
      assert result.id == debt.id
    end

    test "get_debt_obligation_by_identifier/1 returns the debt obligation with given identifier", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      result = FinancialInstruments.get_debt_obligation_by_identifier(debt.debt_identifier)
      assert result.id == debt.id
    end

    test "create_debt_obligation/1 with valid data creates a debt obligation", %{user: user} do
      valid_attrs = %{
        debt_name: "Test Debt",
        debt_type: "LongTermDebt",
        principal_amount: "10000.00",
        outstanding_balance: "8000.00",
        interest_rate: "5.0",
        currency_code: "USD",
        user_id: user.id,
        reporting_period: "2024-Q1",
        debt_identifier: "TEST_DEBT_001",
        measurement_date: ~D[2024-01-15],
        xbrl_concept_identifier: "us-gaap:LongTermDebt",
        xbrl_context_ref: "test-context"
      }

      assert {:ok, debt} = FinancialInstruments.create_debt_obligation(valid_attrs)
      assert debt.debt_name == "Test Debt"
      assert debt.outstanding_balance == Decimal.new("8000.00")
    end

    test "create_debt_obligation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.create_debt_obligation(%{debt_name: nil})
    end

    test "update_debt_obligation/2 with valid data updates the debt obligation", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      update_attrs = %{debt_name: "Updated Debt"}

      assert {:ok, %DebtObligation{} = updated_debt} = FinancialInstruments.update_debt_obligation(debt, update_attrs)
      assert updated_debt.debt_name == "Updated Debt"
    end

    test "update_debt_obligation/2 with invalid data returns error changeset", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.update_debt_obligation(debt, %{debt_name: nil})
    end

    test "delete_debt_obligation/1 deletes the debt obligation", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      assert {:ok, %DebtObligation{}} = FinancialInstruments.delete_debt_obligation(debt)
      assert_raise Ecto.NoResultsError, fn -> FinancialInstruments.get_debt_obligation!(debt.id) end
    end

    test "change_debt_obligation/1 returns a debt obligation changeset", %{user: user} do
      debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = FinancialInstruments.change_debt_obligation(debt)
    end
  end

  describe "cash flow functions" do
    test "list_cash_flows/0 returns all cash flows", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      result = FinancialInstruments.list_cash_flows()
      assert Enum.any?(result, &(&1.id == cash_flow.id))
    end

    test "list_cash_flows_by_user/1 returns cash flows for specific user", %{user: user} do
      cash_flow1 = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      other_user = Factory.insert(:user)
      _cash_flow2 = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: other_user.id})

      result = FinancialInstruments.list_cash_flows_by_user(user.id)
      assert length(result) == 1
      assert List.first(result).id == cash_flow1.id
    end

    test "list_cash_flows_by_user_and_period/2 returns cash flows for specific user and period", %{user: user} do
      cash_flow1 = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id, reporting_period: "2024-Q1"})
      _cash_flow2 = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id, reporting_period: "2024-Q2"})

      result = FinancialInstruments.list_cash_flows_by_user_and_period(user.id, "2024-Q1")
      assert length(result) == 1
      assert List.first(result).id == cash_flow1.id
    end

    test "get_cash_flow!/1 returns the cash flow with given id", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      assert FinancialInstruments.get_cash_flow!(cash_flow.id) == cash_flow
    end

    test "get_cash_flow_by_identifier/1 returns the cash flow with given identifier", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      assert FinancialInstruments.get_cash_flow_by_identifier(cash_flow.cash_flow_identifier) == cash_flow
    end

    test "create_cash_flow/1 with valid data creates a cash flow", %{user: user} do
      valid_attrs = %{
        cash_flow_name: "Test Cash Flow",
        cash_flow_type: "Income",
        cash_flow_category: "Salary",
        amount: "5000.00",
        currency_code: "USD",
        user_id: user.id,
        reporting_period: "2024-Q1",
        cash_flow_identifier: "TEST_CF_001",
        transaction_date: ~D[2024-01-01],
        effective_date: ~D[2024-01-01]
      }

      assert {:ok, cash_flow} = FinancialInstruments.create_cash_flow(valid_attrs)
      assert cash_flow.cash_flow_name == "Test Cash Flow"
      assert cash_flow.amount == Decimal.new("5000.00")
    end

    test "create_cash_flow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.create_cash_flow(%{cash_flow_name: nil})
    end

    test "update_cash_flow/2 with valid data updates the cash flow", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      update_attrs = %{cash_flow_name: "Updated Cash Flow"}

      assert {:ok, %CashFlow{} = updated_cash_flow} = FinancialInstruments.update_cash_flow(cash_flow, update_attrs)
      assert updated_cash_flow.cash_flow_name == "Updated Cash Flow"
    end

    test "update_cash_flow/2 with invalid data returns error changeset", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.update_cash_flow(cash_flow, %{cash_flow_name: nil})
    end

    test "delete_cash_flow/1 deletes the cash flow", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      assert {:ok, %CashFlow{}} = FinancialInstruments.delete_cash_flow(cash_flow)
      assert_raise Ecto.NoResultsError, fn -> FinancialInstruments.get_cash_flow!(cash_flow.id) end
    end

    test "change_cash_flow/1 returns a cash flow changeset", %{user: user} do
      cash_flow = FinancialInstrumentsFixtures.cash_flow_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = FinancialInstruments.change_cash_flow(cash_flow)
    end
  end

  describe "reporting functions" do
    test "generate_cash_flow_report/3 generates comprehensive cash flow report", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      # Create test data
      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{
        cash_flow_type: "Income",
        amount: "4000.00",
        user_id: user.id,
        reporting_period: period
      })

      _expense = FinancialInstrumentsFixtures.cash_flow_fixture(%{
        cash_flow_type: "Expense",
        amount: "2000.00",
        user_id: user.id,
        reporting_period: period
      })

      report = FinancialInstruments.generate_cash_flow_report(user.id, period, currency)

      assert report.user_id == user.id
      assert report.reporting_period == period
      assert report.currency == currency
      assert Decimal.gt?(report.total_income, Decimal.new("0"))
      assert Decimal.gt?(report.total_expenses, Decimal.new("0"))
      assert Decimal.gt?(report.net_cash_flow, Decimal.new("0"))
      assert Decimal.gt?(report.savings_rate, Decimal.new("0"))
      assert is_list(report.income_by_category)
      assert is_list(report.expenses_by_category)
      assert is_list(report.recurring_income)
      assert is_list(report.recurring_expenses)
    end

    test "generate_financial_position_report/3 generates comprehensive financial position report", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      # Create test data
      _asset = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "10000.00",
        user_id: user.id,
        reporting_period: period
      })

      _debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "5000.00",
        monthly_payment: "200.00",
        user_id: user.id,
        reporting_period: period
      })

      report = FinancialInstruments.generate_financial_position_report(user.id, period, currency)

      assert report.user_id == user.id
      assert report.reporting_period == period
      assert report.currency == currency
      assert Decimal.gt?(report.total_assets, Decimal.new("0"))
      assert Decimal.gt?(report.total_debt, Decimal.new("0"))
      assert Decimal.gt?(report.net_worth, Decimal.new("0"))
      assert Decimal.gt?(report.debt_to_asset_ratio, Decimal.new("0"))
      assert is_list(report.assets_by_type)
      assert is_list(report.debts_by_type)
      assert Decimal.gt?(report.monthly_debt_payments, Decimal.new("0"))
    end

    test "generate_comprehensive_net_worth_report/3 generates comprehensive net worth report", %{user: user} do
      period = "2024-Q1"
      currency = "USD"

      # Create test data
      _asset = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "15000.00",
        asset_category: "Savings",
        user_id: user.id,
        reporting_period: period
      })

      _debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{
        outstanding_balance: "5000.00",
        user_id: user.id,
        reporting_period: period
      })

      _income = FinancialInstrumentsFixtures.cash_flow_fixture(%{
        cash_flow_type: "Income",
        amount: "4000.00",
        user_id: user.id,
        reporting_period: period
      })

      _expense = FinancialInstrumentsFixtures.cash_flow_fixture(%{
        cash_flow_type: "Expense",
        amount: "2000.00",
        user_id: user.id,
        reporting_period: period
      })

      report = FinancialInstruments.generate_comprehensive_net_worth_report(user.id, period, currency)

      assert report.user_id == user.id
      assert report.reporting_period == period
      assert report.currency == currency
      assert Decimal.gt?(report.current_net_worth, Decimal.new("0"))
      assert Decimal.gt?(report.total_assets, Decimal.new("0"))
      assert Decimal.gt?(report.total_debt, Decimal.new("0"))
      assert Decimal.gt?(report.debt_to_asset_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.monthly_income, Decimal.new("0"))
      assert Decimal.gt?(report.monthly_expenses, Decimal.new("0"))
      assert Decimal.gt?(report.net_monthly_cash_flow, Decimal.new("0"))
      assert Decimal.gt?(report.savings_rate, Decimal.new("0"))
      assert is_map(report.projected_net_worth)
      assert is_map(report.net_worth_change)
      assert is_integer(report.projection_months)
      assert is_number(report.risk_score)
      assert is_integer(report.financial_stability_score)
      assert Decimal.gt?(report.liquidity_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.emergency_fund_adequacy, Decimal.new("0"))
      assert is_map(report.annual_cash_flow_impact)
      assert Decimal.compare(report.cash_flow_stability, Decimal.new("0")) in [:eq, :gt]
      assert is_integer(report.income_diversity) or is_binary(report.income_diversity)
      assert Decimal.gt?(report.current_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.quick_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.debt_to_income_ratio, Decimal.new("0"))
      assert Decimal.gte?(report.debt_service_coverage_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.emergency_fund_ratio, Decimal.new("0"))
      assert Decimal.gt?(report.investment_to_income_ratio, Decimal.new("0"))
      assert is_list(report.recommendations)
      assert is_list(report.assets_by_type)
      assert is_list(report.debts_by_type)
      assert is_list(report.income_by_category)
      assert is_list(report.expenses_by_category)
      assert is_list(report.recurring_income)
      assert is_list(report.recurring_expenses)
    end

    test "track_net_worth_history/4 tracks net worth changes over time", %{user: user} do
      start_period = "2024-Q1"
      end_period = "2024-Q2"
      currency = "USD"

      # Create test data for both periods
      _asset1 = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "10000.00",
        user_id: user.id,
        reporting_period: start_period
      })

      _asset2 = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "12000.00",
        user_id: user.id,
        reporting_period: end_period
      })

      history = FinancialInstruments.track_net_worth_history(user.id, start_period, end_period, currency)

      assert history.user_id == user.id
      assert history.start_period == start_period
      assert history.end_period == end_period
      assert history.currency == currency
      assert is_list(history.history)
      assert is_map(history.trend_analysis)

      # Check trend analysis
      trend = history.trend_analysis
      assert is_binary(trend.trend)
      assert is_binary(trend.direction)
      assert Decimal.gt?(trend.growth_rate, Decimal.new("0"))
    end

    test "calculate_net_worth_velocity/3 calculates net worth velocity and acceleration", %{user: user} do
      period = "2025-02"
      currency = "USD"

      # Create test data for current and previous periods
      _asset_current = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "12000.00",
        user_id: user.id,
        reporting_period: period
      })

      _asset_previous = FinancialInstrumentsFixtures.asset_fixture(%{
        fair_value: "10000.00",
        user_id: user.id,
        reporting_period: "2025-01"
      })

      velocity = FinancialInstruments.calculate_net_worth_velocity(user.id, period, currency)

      assert velocity.user_id == user.id
      assert velocity.period == period
      assert velocity.currency == currency
      assert Decimal.gt?(velocity.current_net_worth, Decimal.new("0"))
      assert Decimal.gt?(velocity.previous_net_worth, Decimal.new("0"))
      assert Decimal.gt?(velocity.net_worth_change, Decimal.new("0"))
      assert Decimal.gt?(velocity.net_worth_velocity, Decimal.new("0"))
      assert Decimal.gt?(velocity.acceleration, Decimal.new("0"))
      assert is_binary(velocity.velocity_trend)
    end
  end

  describe "XBRL compliance functions" do
    test "validate_all_xbrl_compliance/0 validates all financial instruments", %{user: user} do
      # Create test data
      _asset = FinancialInstrumentsFixtures.asset_fixture(%{user_id: user.id})
      _debt = FinancialInstrumentsFixtures.debt_obligation_fixture(%{user_id: user.id})

      compliance = FinancialInstruments.validate_all_xbrl_compliance()

      assert is_list(compliance.assets)
      assert is_list(compliance.debts)
      assert is_map(compliance.summary)

      summary = compliance.summary
      assert summary.total_assets > 0
      assert summary.total_debts > 0
      assert summary.valid_assets >= 0
      assert summary.valid_debts >= 0
    end
  end
end
