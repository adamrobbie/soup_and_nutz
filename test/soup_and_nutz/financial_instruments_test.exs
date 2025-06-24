defmodule SoupAndNutz.FinancialInstrumentsTest do
  use SoupAndNutz.DataCase, async: true
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation}

  @valid_asset_attrs %{
    asset_identifier: "TEST_ASSET_001",
    asset_name: "Test Asset",
    asset_type: "CashAndCashEquivalents",
    asset_category: "Checking",
    fair_value: Decimal.new("10000.00"),
    book_value: Decimal.new("10000.00"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "TEST_ENTITY",
    reporting_scenario: "Actual",
    description: "Test asset description",
    location: "Test Bank",
    custodian: "Test Bank",
    risk_level: "Low",
    liquidity_level: "High"
  }

  @valid_debt_attrs %{
    debt_identifier: "TEST_DEBT_001",
    debt_name: "Test Debt",
    debt_type: "Mortgage",
    debt_category: "Residential",
    principal_amount: Decimal.new("200000.00"),
    outstanding_balance: Decimal.new("180000.00"),
    interest_rate: Decimal.new("3.75"),
    currency_code: "USD",
    measurement_date: ~D[2024-12-31],
    reporting_period: "2024-12-31",
    reporting_entity: "TEST_ENTITY",
    reporting_scenario: "Actual",
    lender_name: "Test Bank",
    account_number: "123456789",
    maturity_date: ~D[2040-06-15],
    payment_frequency: "Monthly",
    monthly_payment: Decimal.new("1000.00"),
    next_payment_date: ~D[2025-01-15],
    description: "Test debt description",
    is_secured: true,
    collateral_description: "Test collateral",
    risk_level: "Low",
    priority_level: "High"
  }

  describe "assets" do
    alias SoupAndNutz.FinancialInstruments.Asset

    test "list_assets/0 returns all assets" do
      asset = asset_fixture()
      assert FinancialInstruments.list_assets() == [asset]
    end

    test "get_asset!/1 returns the asset with given id" do
      asset = asset_fixture()
      assert FinancialInstruments.get_asset!(asset.id) == asset
    end

    test "create_asset/1 with valid data creates a asset" do
      assert {:ok, %Asset{} = asset} = FinancialInstruments.create_asset(@valid_asset_attrs)
      assert asset.asset_identifier == "TEST_ASSET_001"
      assert asset.asset_name == "Test Asset"
      assert asset.asset_type == "CashAndCashEquivalents"
      assert asset.currency_code == "USD"
      assert Decimal.eq?(asset.fair_value, Decimal.new("10000.00"))
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.create_asset(%{asset_identifier: nil})
    end

    test "update_asset/2 with valid data updates the asset" do
      asset = asset_fixture()
      update_attrs = %{asset_name: "Updated Asset Name", fair_value: Decimal.new("15000.00"), book_value: Decimal.new("15000.00")}
      assert {:ok, %Asset{} = updated_asset} = FinancialInstruments.update_asset(asset, update_attrs)
      assert updated_asset.asset_name == "Updated Asset Name"
      assert Decimal.eq?(updated_asset.fair_value, Decimal.new("15000.00"))
      assert Decimal.eq?(updated_asset.book_value, Decimal.new("15000.00"))
    end

    test "update_asset/2 with invalid data returns error changeset" do
      asset = asset_fixture()
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.update_asset(asset, %{asset_identifier: nil})
      assert asset == FinancialInstruments.get_asset!(asset.id)
    end

    test "delete_asset/1 deletes the asset" do
      asset = asset_fixture()
      assert {:ok, %Asset{}} = FinancialInstruments.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> FinancialInstruments.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset" do
      asset = asset_fixture()
      assert %Ecto.Changeset{} = FinancialInstruments.change_asset(asset)
    end
  end

  describe "debt_obligations" do
    alias SoupAndNutz.FinancialInstruments.DebtObligation

    test "list_debt_obligations/0 returns all debt_obligations" do
      debt_obligation = debt_obligation_fixture()
      assert FinancialInstruments.list_debt_obligations() == [debt_obligation]
    end

    test "get_debt_obligation!/1 returns the debt_obligation with given id" do
      debt_obligation = debt_obligation_fixture()
      assert FinancialInstruments.get_debt_obligation!(debt_obligation.id) == debt_obligation
    end

    test "create_debt_obligation/1 with valid data creates a debt_obligation" do
      assert {:ok, %DebtObligation{} = debt_obligation} = FinancialInstruments.create_debt_obligation(@valid_debt_attrs)
      assert debt_obligation.debt_identifier == "TEST_DEBT_001"
      assert debt_obligation.debt_name == "Test Debt"
      assert debt_obligation.debt_type == "Mortgage"
      assert debt_obligation.currency_code == "USD"
      assert Decimal.eq?(debt_obligation.outstanding_balance, Decimal.new("180000.00"))
    end

    test "create_debt_obligation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.create_debt_obligation(%{debt_identifier: nil})
    end

    test "update_debt_obligation/2 with valid data updates the debt_obligation" do
      debt_obligation = debt_obligation_fixture()
      update_attrs = %{debt_name: "Updated Debt Name", outstanding_balance: Decimal.new("175000.00")}
      assert {:ok, %DebtObligation{} = updated_debt} = FinancialInstruments.update_debt_obligation(debt_obligation, update_attrs)
      assert updated_debt.debt_name == "Updated Debt Name"
      assert Decimal.eq?(updated_debt.outstanding_balance, Decimal.new("175000.00"))
    end

    test "update_debt_obligation/2 with invalid data returns error changeset" do
      debt_obligation = debt_obligation_fixture()
      assert {:error, %Ecto.Changeset{}} = FinancialInstruments.update_debt_obligation(debt_obligation, %{debt_identifier: nil})
      assert debt_obligation == FinancialInstruments.get_debt_obligation!(debt_obligation.id)
    end

    test "delete_debt_obligation/1 deletes the debt_obligation" do
      debt_obligation = debt_obligation_fixture()
      assert {:ok, %DebtObligation{}} = FinancialInstruments.delete_debt_obligation(debt_obligation)
      assert_raise Ecto.NoResultsError, fn -> FinancialInstruments.get_debt_obligation!(debt_obligation.id) end
    end

    test "change_debt_obligation/1 returns a debt_obligation changeset" do
      debt_obligation = debt_obligation_fixture()
      assert %Ecto.Changeset{} = FinancialInstruments.change_debt_obligation(debt_obligation)
    end
  end

  # Helper functions for creating test data
  defp asset_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, @valid_asset_attrs)
    {:ok, asset} = FinancialInstruments.create_asset(attrs)
    asset
  end

  defp debt_obligation_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, @valid_debt_attrs)
    {:ok, debt_obligation} = FinancialInstruments.create_debt_obligation(attrs)
    debt_obligation
  end
end
