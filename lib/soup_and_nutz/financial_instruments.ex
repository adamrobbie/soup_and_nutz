defmodule SoupAndNutz.FinancialInstruments do
  @moduledoc """
  The FinancialInstruments context provides business logic for managing
  assets and debt obligations using XBRL-inspired standards.
  """

  import Ecto.Query, warn: false
  alias SoupAndNutz.Repo
  alias SoupAndNutz.FinancialInstruments.{Asset, DebtObligation, CashFlow}

  # Asset functions

  @doc """
  Returns the list of assets.
  """
  def list_assets do
    Repo.all(Asset)
  end

  @doc """
  Returns the list of assets for a specific entity.
  """
  def list_assets_by_entity(entity) do
    Asset
    |> where([a], a.reporting_entity == ^entity and a.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single asset by ID.
  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  @doc """
  Gets a single asset by identifier.
  """
  def get_asset_by_identifier(identifier) do
    Repo.get_by(Asset, asset_identifier: identifier)
  end

  @doc """
  Creates an asset with XBRL validation.
  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> validate_asset_xbrl_rules()
    |> Repo.insert()
  end

  @doc """
  Updates an asset with XBRL validation.
  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> validate_asset_xbrl_rules()
    |> Repo.update()
  end

  @doc """
  Deletes an asset.
  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.
  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  # Debt Obligation functions

  @doc """
  Returns the list of debt obligations.
  """
  def list_debt_obligations do
    Repo.all(DebtObligation)
  end

  @doc """
  Returns the list of debt obligations for a specific entity.
  """
  def list_debt_obligations_by_entity(entity) do
    DebtObligation
    |> where([d], d.reporting_entity == ^entity and d.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single debt obligation by ID.
  """
  def get_debt_obligation!(id), do: Repo.get!(DebtObligation, id)

  @doc """
  Gets a single debt obligation by identifier.
  """
  def get_debt_obligation_by_identifier(identifier) do
    Repo.get_by(DebtObligation, debt_identifier: identifier)
  end

  @doc """
  Creates a debt obligation with XBRL validation.
  """
  def create_debt_obligation(attrs \\ %{}) do
    %DebtObligation{}
    |> DebtObligation.changeset(attrs)
    |> validate_debt_xbrl_rules()
    |> Repo.insert()
  end

  @doc """
  Updates a debt obligation with XBRL validation.
  """
  def update_debt_obligation(%DebtObligation{} = debt_obligation, attrs) do
    debt_obligation
    |> DebtObligation.changeset(attrs)
    |> validate_debt_xbrl_rules()
    |> Repo.update()
  end

  @doc """
  Deletes a debt obligation.
  """
  def delete_debt_obligation(%DebtObligation{} = debt_obligation) do
    Repo.delete(debt_obligation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking debt obligation changes.
  """
  def change_debt_obligation(%DebtObligation{} = debt_obligation, attrs \\ %{}) do
    DebtObligation.changeset(debt_obligation, attrs)
  end

  # Cash Flow functions

  @doc """
  Returns the list of cash flows.
  """
  def list_cash_flows do
    Repo.all(CashFlow)
  end

  @doc """
  Returns the list of cash flows for a specific entity.
  """
  def list_cash_flows_by_entity(entity) do
    CashFlow
    |> where([c], c.reporting_entity == ^entity and c.is_active == true)
    |> Repo.all()
  end

  @doc """
  Returns the list of cash flows for a specific entity and period.
  """
  def list_cash_flows_by_entity_and_period(entity, period) do
    CashFlow
    |> where([c], c.reporting_entity == ^entity and c.reporting_period == ^period and c.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets a single cash flow by ID.
  """
  def get_cash_flow!(id), do: Repo.get!(CashFlow, id)

  @doc """
  Gets a single cash flow by identifier.
  """
  def get_cash_flow_by_identifier(identifier) do
    Repo.get_by(CashFlow, cash_flow_identifier: identifier)
  end

  @doc """
  Creates a cash flow with XBRL validation.
  """
  def create_cash_flow(attrs \\ %{}) do
    %CashFlow{}
    |> CashFlow.changeset(attrs)
    |> validate_cash_flow_xbrl_rules()
    |> Repo.insert()
  end

  @doc """
  Updates a cash flow with XBRL validation.
  """
  def update_cash_flow(%CashFlow{} = cash_flow, attrs) do
    cash_flow
    |> CashFlow.changeset(attrs)
    |> validate_cash_flow_xbrl_rules()
    |> Repo.update()
  end

  @doc """
  Deletes a cash flow.
  """
  def delete_cash_flow(%CashFlow{} = cash_flow) do
    Repo.delete(cash_flow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cash flow changes.
  """
  def change_cash_flow(%CashFlow{} = cash_flow, attrs \\ %{}) do
    CashFlow.changeset(cash_flow, attrs)
  end

  @doc """
  Generates a cash flow report for a given entity and period.
  """
  def generate_cash_flow_report(entity, period, currency \\ "USD") do
    cash_flows = list_cash_flows_by_entity_and_period(entity, period)

    total_income = CashFlow.total_income(cash_flows, period, entity, currency)
    total_expenses = CashFlow.total_expenses(cash_flows, period, entity, currency)
    net_cash_flow = CashFlow.net_cash_flow(cash_flows, period, entity, currency)

    %{
      entity: entity,
      reporting_period: period,
      currency: currency,
      total_income: total_income,
      total_expenses: total_expenses,
      net_cash_flow: net_cash_flow,
      savings_rate: calculate_savings_rate(total_income, total_expenses),
      income_by_category: CashFlow.group_by_category(cash_flows, "Income"),
      expenses_by_category: CashFlow.group_by_category(cash_flows, "Expense"),
      recurring_income: filter_recurring_cash_flows(cash_flows, "Income"),
      recurring_expenses: filter_recurring_cash_flows(cash_flows, "Expense")
    }
  end

  # Financial reporting functions

  @doc """
  Generates a financial position report for a given entity and period.
  """
  def generate_financial_position_report(entity, period, currency \\ "USD") do
    assets = get_assets_by_entity_and_period(entity, period)
    debts = get_debts_by_entity_and_period(entity, period)

    total_assets = Asset.total_fair_value(assets, currency)
    total_debt = DebtObligation.total_outstanding_debt(debts, currency)
    net_worth = Decimal.sub(total_assets, total_debt)

    %{
      entity: entity,
      reporting_period: period,
      currency: currency,
      total_assets: total_assets,
      total_debt: total_debt,
      net_worth: net_worth,
      debt_to_asset_ratio: calculate_debt_to_asset_ratio(total_debt, total_assets),
      assets_by_type: group_assets_by_type(assets),
      debts_by_type: group_debts_by_type(debts),
      monthly_debt_payments: DebtObligation.total_monthly_payments(debts, currency)
    }
  end

  @doc """
  Validates all financial instruments for XBRL compliance.
  """
  def validate_all_xbrl_compliance do
    assets = list_assets()
    debts = list_debt_obligations()

    asset_validation = Enum.map(assets, &validate_asset_xbrl_compliance/1)
    debt_validation = Enum.map(debts, &validate_debt_xbrl_compliance/1)

    %{
      assets: asset_validation,
      debts: debt_validation,
      summary: %{
        total_assets: length(assets),
        total_debts: length(debts),
        valid_assets: Enum.count(asset_validation, & &1.valid),
        valid_debts: Enum.count(debt_validation, & &1.valid)
      }
    }
  end

  # Private functions

  defp validate_asset_xbrl_rules(changeset) do
    asset = Ecto.Changeset.apply_changes(changeset)
    {valid, errors} = Asset.validate_xbrl_rules(asset)
    if valid do
      changeset
    else
      Enum.reduce(errors, changeset, fn {field, message}, acc ->
        Ecto.Changeset.add_error(acc, field, message)
      end)
    end
  end

  defp validate_debt_xbrl_rules(changeset) do
    debt = Ecto.Changeset.apply_changes(changeset)
    {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
    if valid do
      changeset
    else
      Enum.reduce(errors, changeset, fn {field, message}, acc ->
        Ecto.Changeset.add_error(acc, field, message)
      end)
    end
  end

  defp validate_cash_flow_xbrl_rules(changeset) do
    cash_flow = Ecto.Changeset.apply_changes(changeset)
    {valid, errors} = CashFlow.validate_cash_flow_rules(cash_flow)
    if valid do
      changeset
    else
      Enum.reduce(errors, changeset, fn {field, message}, acc ->
        Ecto.Changeset.add_error(acc, field, message)
      end)
    end
  end

  defp get_assets_by_entity_and_period(entity, period) do
    Asset
    |> where([a], a.reporting_entity == ^entity and a.reporting_period == ^period and a.is_active == true)
    |> Repo.all()
  end

  defp get_debts_by_entity_and_period(entity, period) do
    DebtObligation
    |> where([d], d.reporting_entity == ^entity and d.reporting_period == ^period and d.is_active == true)
    |> Repo.all()
  end

  defp calculate_debt_to_asset_ratio(total_debt, total_assets) do
    if Decimal.eq?(total_assets, Decimal.new("0")) do
      Decimal.new("0")
    else
      Decimal.div(total_debt, total_assets)
    end
  end

  defp group_assets_by_type(assets) do
    assets
    |> Enum.group_by(& &1.asset_type)
    |> Enum.map(fn {type, type_assets} ->
      total_value = Enum.reduce(type_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      {type, total_value}
    end)
    |> Enum.sort_by(fn {_type, value} -> value end, :desc)
  end

  defp group_debts_by_type(debts) do
    debts
    |> Enum.group_by(& &1.debt_type)
    |> Enum.map(fn {type, type_debts} ->
      total_value = Enum.reduce(type_debts, Decimal.new("0"), fn debt, acc ->
        Decimal.add(acc, debt.outstanding_balance)
      end)
      {type, total_value}
    end)
    |> Enum.sort_by(fn {_type, value} -> value end, :desc)
  end

  defp validate_asset_xbrl_compliance(asset) do
    {valid, errors} = Asset.validate_xbrl_rules(asset)
    %{
      asset_id: asset.id,
      asset_identifier: asset.asset_identifier,
      valid: valid,
      errors: errors
    }
  end

  defp validate_debt_xbrl_compliance(debt) do
    {valid, errors} = DebtObligation.validate_xbrl_rules(debt)
    %{
      debt_id: debt.id,
      debt_identifier: debt.debt_identifier,
      valid: valid,
      errors: errors
    }
  end

  defp calculate_savings_rate(total_income, total_expenses) do
    if Decimal.eq?(total_income, Decimal.new("0")) do
      Decimal.new("0")
    else
      net_savings = Decimal.sub(total_income, total_expenses)
      Decimal.mult(Decimal.div(net_savings, total_income), Decimal.new("100"))
    end
  end

  defp filter_recurring_cash_flows(cash_flows, type) do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == type && &1.is_recurring))
    |> Enum.sort_by(& &1.next_occurrence_date)
  end
end
