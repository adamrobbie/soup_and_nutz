defmodule SoupAndNutzWeb.BudgetTrackingLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.{BudgetPlanner, FinancialInstruments}
  alias SoupAndNutz.FinancialInstruments.CashFlow

  # Add auth hook to ensure current_user is set
  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    current_period = get_current_period()

    # Get budget data
    budget = BudgetPlanner.create_budget(user_id, current_period, "50/30/20")
    performance = BudgetPlanner.analyze_budget_performance(user_id, current_period, budget)
    alerts = BudgetPlanner.check_budget_alerts(user_id, current_period, budget)

    # Get recent transactions
    recent_transactions = FinancialInstruments.list_cash_flows_by_user_and_period(user_id, current_period)

    # Get spending trends (last 3 months)
    spending_trends = get_spending_trends(user_id, 3)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:current_period, current_period)
      |> assign(:budget, budget)
      |> assign(:performance, performance)
      |> assign(:alerts, alerts)
      |> assign(:recent_transactions, recent_transactions)
      |> assign(:spending_trends, spending_trends)
      |> assign(:selected_category, nil)
      |> assign(:show_budget_modal, false)
      |> assign(:page_title, "Budget Tracking")

    {:ok, socket}
  end

  @impl true
  def handle_event("set_budget_target", %{"category" => category, "amount" => amount}, socket) do
    user_id = socket.assigns.user_id
    period = socket.assigns.current_period

    # Create a budget target cash flow
    budget_params = %{
      user_id: user_id,
      cash_flow_identifier: "BUDGET_#{category}_#{period}",
      cash_flow_name: "#{category} Budget Target",
      cash_flow_type: "Budget",
      cash_flow_category: category,
      amount: Decimal.new(amount),
      currency_code: "USD",
      transaction_date: Date.utc_today(),
      effective_date: Date.utc_today(),
      reporting_period: period,
      is_budget_item: true,
      budget_category: category,
      description: "Monthly budget target for #{category}"
    }

    case FinancialInstruments.create_cash_flow(budget_params) do
      {:ok, _budget_flow} ->
        # Refresh budget data
        budget = BudgetPlanner.create_budget(user_id, period, "50/30/20")
        performance = BudgetPlanner.analyze_budget_performance(user_id, period, budget)
        alerts = BudgetPlanner.check_budget_alerts(user_id, period, budget)

        socket =
          socket
          |> assign(:budget, budget)
          |> assign(:performance, performance)
          |> assign(:alerts, alerts)
          |> put_flash(:info, "Budget target set for #{category}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to set budget target")}
    end
  end

  @impl true
  def handle_event("show_budget_modal", %{"category" => category}, socket) do
    socket =
      socket
      |> assign(:selected_category, category)
      |> assign(:show_budget_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_budget_modal", _params, socket) do
    socket =
      socket
      |> assign(:selected_category, nil)
      |> assign(:show_budget_modal, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_period", %{"period" => period}, socket) do
    user_id = socket.assigns.user_id

    # Refresh data for new period
    budget = BudgetPlanner.create_budget(user_id, period, "50/30/20")
    performance = BudgetPlanner.analyze_budget_performance(user_id, period, budget)
    alerts = BudgetPlanner.check_budget_alerts(user_id, period, budget)
    recent_transactions = FinancialInstruments.list_cash_flows_by_user_and_period(user_id, period)

    socket =
      socket
      |> assign(:current_period, period)
      |> assign(:budget, budget)
      |> assign(:performance, performance)
      |> assign(:alerts, alerts)
      |> assign(:recent_transactions, recent_transactions)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-black min-h-screen">
      <div class="px-6 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-white">Budget Tracking</h1>
          <p class="text-gray-400 mt-2">Track your spending against budget targets in real-time</p>
        </div>

        <!-- Period Selector -->
        <div class="mb-6">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-4">
            <label class="block text-sm font-medium text-gray-300 mb-2">Select Period</label>
            <select
              phx-change="change_period"
              name="period"
              class="bg-gray-800 border border-gray-700 text-white rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <%= for period <- get_available_periods() do %>
                <option value={period} selected={@current_period == period}>
                  <%= format_period(period) %>
                </option>
              <% end %>
            </select>
          </div>
        </div>

        <!-- Budget Alerts -->
        <%= if @alerts.alert_count > 0 do %>
          <div class="mb-8">
            <div class="bg-red-900 border border-red-800 rounded-lg p-4">
              <div class="flex items-center mb-3">
                <div class="flex-shrink-0">
                  <svg class="w-5 h-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-red-300">Budget Alerts (<%= @alerts.alert_count %>)</h3>
                </div>
              </div>
              <div class="space-y-2">
                <%= for alert <- @alerts.alerts do %>
                  <div class="flex items-center justify-between bg-red-800 rounded p-3">
                    <div class="flex items-center">
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mr-3",
                        alert_severity_class(alert.severity)
                      ]}>
                        <%= String.upcase(alert.severity) %>
                      </span>
                      <span class="text-red-100 text-sm"><%= alert.message %></span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Budget Overview Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-green-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-green-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Total Income</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_currency(@budget.total_income) %>
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-blue-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Budget Performance</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_percentage(@performance.overall_performance.score) %>%
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-purple-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-purple-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Savings Achieved</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_currency(@performance.savings_achieved) %>
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-yellow-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-yellow-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Active Alerts</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= @alerts.alert_count %>
                </dd>
              </div>
            </div>
          </div>
        </div>

        <!-- Budget Categories Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <!-- Budget vs Actual -->
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-6">Budget vs Actual</h2>
            <div class="space-y-4">
              <%= for category_perf <- @performance.category_performance do %>
                <div class="bg-gray-800 rounded-lg p-4">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-white font-medium"><%= category_perf.category %></span>
                    <button
                      phx-click="show_budget_modal"
                      phx-value-category={category_perf.category}
                      class="text-blue-400 hover:text-blue-300 text-sm"
                    >
                      Set Target
                    </button>
                  </div>

                  <div class="flex justify-between text-sm text-gray-400 mb-2">
                    <span>Budget: <%= format_currency(category_perf.budgeted) %></span>
                    <span>Actual: <%= format_currency(category_perf.actual) %></span>
                  </div>

                  <div class="w-full bg-gray-700 rounded-full h-2 mb-2">
                    <div class={[
                      "h-2 rounded-full transition-all duration-300",
                      progress_bar_class(category_perf.status)
                    ]} style={"width: #{min(100, max(0, Decimal.to_float(category_perf.variance_percentage)))}%"}>
                    </div>
                  </div>

                  <div class="flex justify-between text-xs">
                    <span class={variance_text_class(category_perf.status)}>
                      <%= format_variance(category_perf.variance) %>
                    </span>
                    <span class={status_class(category_perf.status)}>
                      <%= String.upcase(category_perf.status) %>
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Recent Transactions -->
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-6">Recent Transactions</h2>
            <div class="space-y-3">
              <%= for transaction <- Enum.take(@recent_transactions, 10) do %>
                <div class="flex items-center justify-between bg-gray-800 rounded-lg p-3">
                  <div class="flex items-center">
                    <div class={[
                      "w-3 h-3 rounded-full mr-3",
                      transaction_type_color(transaction.cash_flow_type)
                    ]}></div>
                    <div>
                      <div class="text-white font-medium"><%= transaction.cash_flow_name %></div>
                      <div class="text-gray-400 text-sm"><%= transaction.cash_flow_category %></div>
                    </div>
                  </div>
                  <div class="text-right">
                    <div class={[
                      "font-medium",
                      transaction_amount_color(transaction.cash_flow_type)
                    ]}>
                      <%= format_currency(transaction.amount) %>
                    </div>
                    <div class="text-gray-400 text-xs">
                      <%= Calendar.strftime(transaction.transaction_date, "%b %d") %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Spending Trends Chart -->
        <div class="bg-gray-900 border border-gray-800 rounded-lg p-6 mb-8">
          <h2 class="text-xl font-semibold text-white mb-6">Spending Trends</h2>
          <div class="h-64">
            <!-- Chart placeholder - you can integrate with Chart.js or similar -->
            <div class="flex items-center justify-center h-full text-gray-400">
              <div class="text-center">
                <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                </svg>
                <p>Spending trends chart will be displayed here</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Budget Target Modal -->
      <%= if @show_budget_modal do %>
        <.modal id="budget-modal" show={true}>
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-4">
              Set Budget Target for <%= @selected_category %>
            </h2>

            <form phx-submit="set_budget_target" phx-value-category={@selected_category}>
              <input type="hidden" name="category" value={@selected_category} />

              <div class="mb-4">
                <label class="block text-sm font-medium text-gray-300 mb-2">
                  Monthly Budget Amount
                </label>
                <input
                  type="number"
                  name="amount"
                  step="0.01"
                  min="0"
                  required
                  class="w-full bg-gray-800 border border-gray-700 text-white rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter amount..."
                />
              </div>

              <div class="flex justify-end space-x-3">
                <button
                  type="button"
                  phx-click="close_budget_modal"
                  class="px-4 py-2 text-gray-300 hover:text-white transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors"
                >
                  Set Target
                </button>
              </div>
            </form>
          </div>
        </.modal>
      <% end %>
    </div>
    """
  end

  # Helper functions
  defp get_current_period do
    Date.utc_today()
    |> Date.to_string()
    |> String.slice(0, 7)
  end

  defp get_available_periods do
    # Generate last 12 months
    today = Date.utc_today()
    Enum.map(0..11, fn months_ago ->
      Date.add(today, -months_ago * 30)
      |> Date.to_string()
      |> String.slice(0, 7)
    end)
    |> Enum.reverse()
  end

  defp format_period(period) do
    [year, month] = String.split(period, "-")
    month_name = Date.new(String.to_integer(year), String.to_integer(month), 1)
    |> elem(1)
    |> Calendar.strftime("%B %Y")
    month_name
  end

  defp get_spending_trends(user_id, months_back) do
    # Get spending data for trend analysis
    today = Date.utc_today()
    Enum.map(0..(months_back - 1), fn months_ago ->
      period = Date.add(today, -months_ago * 30)
      |> Date.to_string()
      |> String.slice(0, 7)

      cash_flows = FinancialInstruments.list_cash_flows_by_user_and_period(user_id, period)
      total_expenses = CashFlow.total_expenses(cash_flows, period, user_id)

      {period, total_expenses}
    end)
    |> Enum.reverse()
  end

  defp format_currency(amount) do
    case amount do
      %Decimal{} -> "$#{Decimal.to_string(amount)}"
      _ -> "$0.00"
    end
  end

  defp format_percentage(amount) do
    case amount do
      %Decimal{} -> Decimal.round(amount, 1) |> Decimal.to_string()
      _ -> "0.0"
    end
  end

  defp format_variance(variance) do
    case variance do
      %Decimal{} ->
        if Decimal.gt?(variance, Decimal.new("0")) do
          "+#{format_currency(variance)}"
        else
          format_currency(Decimal.abs(variance))
        end
      _ -> "$0.00"
    end
  end

  defp progress_bar_class(status) do
    case status do
      "under_budget" -> "bg-green-500"
      "on_budget" -> "bg-blue-500"
      "over_budget" -> "bg-red-500"
      _ -> "bg-gray-500"
    end
  end

  defp variance_text_class(status) do
    case status do
      "under_budget" -> "text-green-400"
      "on_budget" -> "text-blue-400"
      "over_budget" -> "text-red-400"
      _ -> "text-gray-400"
    end
  end

  defp status_class(status) do
    case status do
      "under_budget" -> "text-green-400"
      "on_budget" -> "text-blue-400"
      "over_budget" -> "text-red-400"
      _ -> "text-gray-400"
    end
  end

  defp alert_severity_class(severity) do
    case severity do
      "high" -> "bg-red-100 text-red-800"
      "medium" -> "bg-yellow-100 text-yellow-800"
      "low" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp transaction_type_color(type) do
    case type do
      "Income" -> "bg-green-500"
      "Expense" -> "bg-red-500"
      "Budget" -> "bg-blue-500"
      _ -> "bg-gray-500"
    end
  end

  defp transaction_amount_color(type) do
    case type do
      "Income" -> "text-green-400"
      "Expense" -> "text-red-400"
      "Budget" -> "text-blue-400"
      _ -> "text-gray-400"
    end
  end
end
