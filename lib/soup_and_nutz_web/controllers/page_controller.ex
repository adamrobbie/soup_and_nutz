defmodule SoupAndNutzWeb.PageController do
  use SoupAndNutzWeb, :controller
  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.Accounts

  def home(conn, _params) do
    # Get current user or nil if not authenticated
    current_user = get_current_user_or_fallback(conn)

    if current_user do
      # User is authenticated - show dashboard
      render_authenticated_dashboard(conn, current_user)
    else
      # No authenticated user - show welcome page
      render_welcome_page(conn)
    end
  end

  # Private helper functions

  defp get_current_user_or_fallback(conn) do
    # Check if user is authenticated via conn.assigns
    case conn.assigns[:current_user] do
      %Accounts.User{} = user -> user
      _ ->
        # No authenticated user - return nil to show welcome message
        nil
    end
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
        Decimal.add(acc, asset.fair_value || asset.book_value || Decimal.new("0"))
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
        Decimal.add(acc, debt.outstanding_balance || debt.principal_amount || Decimal.new("0"))
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
        Decimal.add(acc, asset.fair_value || asset.book_value || Decimal.new("0"))
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
        Decimal.add(acc, debt.outstanding_balance || debt.principal_amount || Decimal.new("0"))
      end)
      %{
        currency: currency,
        value: total_value,
        count: length(currency_debts)
      }
    end)
    |> Enum.sort_by(& &1.value, :desc)
  end

  defp render_authenticated_dashboard(conn, current_user) do
    # Fetch dashboard data for the current user
    assets = FinancialInstruments.list_assets_by_user(current_user.id)
    debt_obligations = FinancialInstruments.list_debt_obligations_by_user(current_user.id)
    _cash_flows = FinancialInstruments.list_cash_flows_by_user(current_user.id)

    # Use current user's preferences
    period = current_user.default_reporting_period || "2024-12-31"
    currency = current_user.preferred_currency || "USD"

    # Calculate summary statistics
    total_assets = Enum.reduce(assets, Decimal.new("0"), fn asset, acc ->
      Decimal.add(acc, asset.fair_value || asset.book_value || Decimal.new("0"))
    end)

    total_debt = Enum.reduce(debt_obligations, Decimal.new("0"), fn debt, acc ->
      Decimal.add(acc, debt.outstanding_balance || debt.principal_amount || Decimal.new("0"))
    end)

    net_worth = Decimal.sub(total_assets, total_debt)

    # Cash flow summaries using user ID instead of string entity
    cash_flow_report = FinancialInstruments.generate_cash_flow_report(current_user.id, period, currency)
    total_income = cash_flow_report.total_income
    total_expenses = cash_flow_report.total_expenses
    net_cash_flow = cash_flow_report.net_cash_flow
    savings_rate = cash_flow_report.savings_rate

    # Group data for charts
    assets_by_type = group_assets_by_type(assets)
    debts_by_type = group_debts_by_type(debt_obligations)
    assets_by_currency = group_assets_by_currency(assets)
    debts_by_currency = group_debts_by_currency(debt_obligations)

    # Get recent activity
    recent_assets = Enum.take(assets, 5)
    recent_debts = Enum.take(debt_obligations, 5)

    dashboard_data = %{
      current_user: current_user,
      summary: %{
        total_assets: total_assets,
        total_debt: total_debt,
        net_worth: net_worth,
        asset_count: length(assets),
        debt_count: length(debt_obligations),
        debt_to_asset_ratio: calculate_debt_to_asset_ratio(total_debt, total_assets),
        total_income: total_income,
        total_expenses: total_expenses,
        net_cash_flow: net_cash_flow,
        savings_rate: savings_rate
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

    # Use the default app layout with sidebar navigation
    render(conn, :home, dashboard_data: dashboard_data)
  end

  defp render_welcome_page(conn) do
    # Show welcome page for unauthenticated users, with no layout
    conn
    |> put_layout(false)
    |> render(:welcome)
  end
end
