defmodule SoupAndNutzWeb.PageController do
  use SoupAndNutzWeb, :controller
  alias SoupAndNutz.FinancialInstruments

  def home(conn, _params) do
    # Fetch dashboard data
    assets = FinancialInstruments.list_assets()
    debt_obligations = FinancialInstruments.list_debt_obligations()

    # Calculate summary statistics
    total_assets = calculate_total_assets(assets)
    total_debt = calculate_total_debt(debt_obligations)
    net_worth = Decimal.sub(total_assets, total_debt)

    # Group data for charts
    assets_by_type = group_assets_by_type(assets)
    debts_by_type = group_debts_by_type(debt_obligations)
    assets_by_currency = group_assets_by_currency(assets)
    debts_by_currency = group_debts_by_currency(debt_obligations)

    # Get recent activity
    recent_assets = Enum.take(assets, 5)
    recent_debts = Enum.take(debt_obligations, 5)

    dashboard_data = %{
      summary: %{
        total_assets: total_assets,
        total_debt: total_debt,
        net_worth: net_worth,
        asset_count: length(assets),
        debt_count: length(debt_obligations),
        debt_to_asset_ratio: calculate_debt_to_asset_ratio(total_debt, total_assets)
      },
      charts: %{
        assets_by_type: assets_by_type,
        debts_by_type: debts_by_type,
        assets_by_currency: assets_by_currency,
        debts_by_currency: debts_by_currency
      },
      recent_activity: %{
        assets: recent_assets,
        debts: recent_debts
      }
    }

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, dashboard_data: dashboard_data)
  end

  # Private helper functions

  defp calculate_total_assets(assets) do
    assets
    |> Enum.reduce(Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value)
    end)
  end

  defp calculate_total_debt(debts) do
    debts
    |> Enum.reduce(Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance)
    end)
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
      %{
        type: type,
        value: total_value,
        count: length(type_assets),
        percentage: 0 # Will be calculated in template
      }
    end)
    |> Enum.sort_by(& &1.value, :desc)
  end

  defp group_debts_by_type(debts) do
    debts
    |> Enum.group_by(& &1.debt_type)
    |> Enum.map(fn {type, type_debts} ->
      total_value = Enum.reduce(type_debts, Decimal.new("0"), fn debt, acc ->
        Decimal.add(acc, debt.outstanding_balance)
      end)
      %{
        type: type,
        value: total_value,
        count: length(type_debts),
        percentage: 0 # Will be calculated in template
      }
    end)
    |> Enum.sort_by(& &1.value, :desc)
  end

  defp group_assets_by_currency(assets) do
    assets
    |> Enum.group_by(& &1.currency_code)
    |> Enum.map(fn {currency, currency_assets} ->
      total_value = Enum.reduce(currency_assets, Decimal.new("0"), fn asset, acc ->
        Decimal.add(acc, asset.fair_value)
      end)
      %{
        currency: currency,
        value: total_value,
        count: length(currency_assets)
      }
    end)
    |> Enum.sort_by(& &1.value, :desc)
  end

  defp group_debts_by_currency(debts) do
    debts
    |> Enum.group_by(& &1.currency_code)
    |> Enum.map(fn {currency, currency_debts} ->
      total_value = Enum.reduce(currency_debts, Decimal.new("0"), fn debt, acc ->
        Decimal.add(acc, debt.outstanding_balance)
      end)
      %{
        currency: currency,
        value: total_value,
        count: length(currency_debts)
      }
    end)
    |> Enum.sort_by(& &1.value, :desc)
  end
end
