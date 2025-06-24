defmodule SoupAndNutz.FinancialInstrumentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoupAndNutz.FinancialInstruments` context.
  """

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation}

  @doc """
  Generate a asset.
  """
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        asset_identifier: "ASSET#{System.unique_integer()}",
        asset_name: "Test Asset #{System.unique_integer()}",
        asset_type: "EQUITY_SECURITIES",
        fair_value: "10000.00",
        currency_code: "USD",
        reporting_entity: "Test Corp",
        reporting_period: "2024-Q1",
        is_active: true,
        acquisition_date: ~D[2024-01-01],
        last_valuation_date: ~D[2024-01-15]
      })
      |> FinancialInstruments.create_asset()

    asset
  end

  @doc """
  Generate a debt_obligation.
  """
  def debt_obligation_fixture(attrs \\ %{}) do
    {:ok, debt_obligation} =
      attrs
      |> Enum.into(%{
        debt_identifier: "DEBT#{System.unique_integer()}",
        debt_name: "Test Debt #{System.unique_integer()}",
        debt_type: "MORTGAGE",
        outstanding_balance: "50000.00",
        interest_rate: "3.50",
        currency_code: "USD",
        reporting_entity: "Test Corp",
        reporting_period: "2024-Q1",
        is_active: true,
        maturity_date: ~D[2040-01-01],
        payment_frequency: "MONTHLY",
        collateral_type: "REAL_ESTATE"
      })
      |> FinancialInstruments.create_debt_obligation()

    debt_obligation
  end

  @doc """
  Generate a list of assets for testing.
  """
  def asset_list_fixture(count \\ 3) do
    Enum.map(1..count, fn i ->
      asset_fixture(%{
        asset_identifier: "ASSET#{i}",
        asset_name: "Test Asset #{i}",
        fair_value: "#{i * 10000}.00"
      })
    end)
  end

  @doc """
  Generate a list of debt obligations for testing.
  """
  def debt_obligation_list_fixture(count \\ 3) do
    Enum.map(1..count, fn i ->
      debt_obligation_fixture(%{
        debt_identifier: "DEBT#{i}",
        debt_name: "Test Debt #{i}",
        outstanding_balance: "#{i * 25000}.00"
      })
    end)
  end

  @doc """
  Generate test data for dashboard testing.
  """
  def dashboard_test_data_fixture do
    # Create assets with different types and currencies
    equity_asset = asset_fixture(%{
      asset_identifier: "EQUITY001",
      asset_name: "Stock Portfolio",
      asset_type: "EQUITY_SECURITIES",
      fair_value: "50000.00",
      currency_code: "USD"
    })

    bond_asset = asset_fixture(%{
      asset_identifier: "BOND001",
      asset_name: "Government Bonds",
      asset_type: "FIXED_INCOME_SECURITIES",
      fair_value: "30000.00",
      currency_code: "USD"
    })

    real_estate_asset = asset_fixture(%{
      asset_identifier: "REAL001",
      asset_name: "Investment Property",
      asset_type: "REAL_ESTATE",
      fair_value: "200000.00",
      currency_code: "USD"
    })

    # Create debts with different types
    mortgage_debt = debt_obligation_fixture(%{
      debt_identifier: "MORTGAGE001",
      debt_name: "Home Mortgage",
      debt_type: "MORTGAGE",
      outstanding_balance: "150000.00",
      currency_code: "USD"
    })

    credit_card_debt = debt_obligation_fixture(%{
      debt_identifier: "CC001",
      debt_name: "Credit Card",
      debt_type: "CREDIT_CARD",
      outstanding_balance: "5000.00",
      currency_code: "USD"
    })

    %{
      assets: [equity_asset, bond_asset, real_estate_asset],
      debts: [mortgage_debt, credit_card_debt]
    }
  end
end
