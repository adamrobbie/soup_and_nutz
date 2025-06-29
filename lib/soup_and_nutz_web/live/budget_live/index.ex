defmodule SoupAndNutzWeb.BudgetLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.BudgetPlanner

  # Add auth hook to ensure current_user is set
  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id  # Get from current_user instead of hardcoding
    period = "2025-01"

    # Load initial data
    budget = BudgetPlanner.create_budget(user_id, period, "50/30/20")
    performance = BudgetPlanner.analyze_budget_performance(user_id, period, budget)
    alerts = BudgetPlanner.check_budget_alerts(user_id, period, budget)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:period, period)
      |> assign(:budget, budget)
      |> assign(:performance, performance)
      |> assign(:alerts, alerts)
      |> assign(:selected_budget_type, "50/30/20")
      |> assign(:show_optimization, false)
      |> assign(:optimization_results, nil)
      |> assign(:page_title, "Budget Planner")

    {:ok, socket}
  end

  @impl true
  def handle_event("change_budget_type", %{"budget_type" => budget_type}, socket) do
    user_id = socket.assigns.user_id
    period = socket.assigns.period

    # Create new budget with selected type
    new_budget = BudgetPlanner.create_budget(user_id, period, budget_type)
    new_performance = BudgetPlanner.analyze_budget_performance(user_id, period, new_budget)
    new_alerts = BudgetPlanner.check_budget_alerts(user_id, period, new_budget)

    socket =
      socket
      |> assign(:budget, new_budget)
      |> assign(:performance, new_performance)
      |> assign(:alerts, new_alerts)
      |> assign(:selected_budget_type, budget_type)
      |> put_flash(:info, "Budget updated to #{budget_type} method")

    {:noreply, socket}
  end

  @impl true
  def handle_event("optimize_budget", _params, socket) do
    user_id = socket.assigns.user_id
    period = socket.assigns.period
    budget = socket.assigns.budget

    # Generate optimization recommendations
    financial_goals = []  # In a real app, load from user preferences
    optimization = BudgetPlanner.optimize_budget(user_id, period, budget, financial_goals)

    socket =
      socket
      |> assign(:show_optimization, true)
      |> assign(:optimization_results, optimization)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_alert", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    current_alerts = socket.assigns.alerts.alerts
    updated_alerts = List.delete_at(current_alerts, index)

    updated_alert_data = %{socket.assigns.alerts | alerts: updated_alerts, alert_count: length(updated_alerts)}

    socket = assign(socket, :alerts, updated_alert_data)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-black min-h-screen">
      <div class="px-6 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-white">Budget Planner</h1>
          <p class="text-gray-400 mt-2">Manage your budget with intelligent insights and recommendations</p>
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
                <%= for {alert, index} <- Enum.with_index(@alerts.alerts) do %>
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
                    <button
                      phx-click="dismiss_alert"
                      phx-value-index={index}
                      class="text-red-300 hover:text-red-100"
                    >
                      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
                      </svg>
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Budget Type Selection -->
        <div class="mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-4">Budget Strategy</h2>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <%= for {type, description} <- budget_type_options() do %>
                <button
                  phx-click="change_budget_type"
                  phx-value-budget_type={type}
                  class={[
                    "p-4 rounded-lg border text-left transition-colors",
                    if(@selected_budget_type == type,
                      do: "border-blue-500 bg-blue-900 text-blue-100",
                      else: "border-gray-700 bg-gray-800 text-gray-300 hover:border-gray-600")
                  ]}
                >
                  <div class="font-medium"><%= type %></div>
                  <div class="text-sm opacity-75 mt-1"><%= description %></div>
                </button>
              <% end %>
            </div>
          </div>
        </div>

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
                <dt class="text-sm font-medium text-gray-400">Savings Goal</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_currency(@budget.savings_goal) %>
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-yellow-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-yellow-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Status</dt>
                <dd class="text-xl font-semibold text-white capitalize">
                  <%= @performance.overall_performance.status %>
                </dd>
              </div>
            </div>
          </div>
        </div>

        <!-- Budget Allocation Chart -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-white mb-4">Budget Allocation</h3>
            <div class="space-y-4">
              <%= for {category, amount} <- @budget.budget_allocation do %>
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-3 h-3 bg-blue-500 rounded-full mr-3"></div>
                    <span class="text-gray-300"><%= category %></span>
                  </div>
                  <div class="text-right">
                    <div class="text-white font-medium"><%= format_currency(amount) %></div>
                    <div class="text-gray-400 text-sm">
                      <%= format_percentage(calculate_percentage(amount, @budget.total_income)) %>%
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-white">Budget vs Actual</h3>
              <button
                phx-click="optimize_budget"
                class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Optimize Budget
              </button>
            </div>
            <div class="space-y-4">
              <%= for category_performance <- @performance.category_performance do %>
                <div class="space-y-2">
                  <div class="flex items-center justify-between">
                    <span class="text-gray-300 text-sm"><%= category_performance.category %></span>
                    <span class={[
                      "text-xs px-2 py-1 rounded-full",
                      performance_status_class(category_performance.status)
                    ]}>
                      <%= format_status(category_performance.status) %>
                    </span>
                  </div>
                  <div class="flex items-center space-x-2 text-xs text-gray-400">
                    <span>Budget: <%= format_currency(category_performance.budgeted) %></span>
                    <span>•</span>
                    <span>Actual: <%= format_currency(category_performance.actual) %></span>
                    <span>•</span>
                    <span class={variance_color(category_performance.variance)}>
                      <%= format_variance(category_performance.variance) %>
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Optimization Results -->
        <%= if @show_optimization and @optimization_results do %>
          <div class="mb-8">
            <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
              <h3 class="text-lg font-semibold text-white mb-4">Budget Optimization Recommendations</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h4 class="text-md font-medium text-white mb-3">Optimization Suggestions</h4>
                  <div class="space-y-3">
                    <%= for suggestion <- @optimization_results.optimization_suggestions do %>
                      <div class="bg-gray-800 rounded-lg p-4">
                        <div class="flex items-center justify-between mb-2">
                          <span class="text-sm font-medium text-white capitalize">
                            <%= String.replace(suggestion.type, "_", " ") %>
                          </span>
                          <span class={[
                            "text-xs px-2 py-1 rounded-full",
                            priority_class(Map.get(suggestion, :priority, "medium"))
                          ]}>
                            <%= Map.get(suggestion, :priority, "medium") |> String.upcase() %>
                          </span>
                        </div>
                        <p class="text-gray-300 text-sm">
                          <%= Map.get(suggestion, :description, "Optimization suggestion") %>
                        </p>
                        <%= if Map.has_key?(suggestion, :potential_savings) do %>
                          <div class="mt-2 text-green-400 text-sm">
                            Potential savings: <%= format_currency(suggestion.potential_savings) %>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
                <div>
                  <h4 class="text-md font-medium text-white mb-3">Projected Impact</h4>
                  <div class="bg-gray-800 rounded-lg p-4">
                    <div class="space-y-3">
                      <div class="flex justify-between">
                        <span class="text-gray-300">Current Performance:</span>
                        <span class="text-white">
                          <%= format_percentage(@optimization_results.current_performance.score) %>%
                        </span>
                      </div>
                      <div class="flex justify-between">
                        <span class="text-gray-300">Projected Savings:</span>
                        <span class="text-green-400">
                          <%= format_currency(@optimization_results.projected_savings) %>
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Recommendations -->
        <%= if length(@performance.recommendations) > 0 do %>
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-white mb-4">Recommendations</h3>
            <div class="space-y-3">
              <%= for recommendation <- @performance.recommendations do %>
                <div class="flex items-start">
                  <div class="flex-shrink-0 mt-1">
                    <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
                  </div>
                  <p class="ml-3 text-gray-300 text-sm"><%= recommendation %></p>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper functions

  defp budget_type_options do
    [
      {"50/30/20", "50% needs, 30% wants, 20% savings"},
      {"zero_based", "Every dollar has a purpose"},
      {"envelope", "Category-based spending limits"},
      {"custom", "Based on your financial goals"}
    ]
  end

  defp format_currency(decimal) when is_struct(decimal, Decimal) do
    "$" <> (decimal |> Decimal.round(2) |> Decimal.to_string())
  end
  defp format_currency(_), do: "$0.00"

  defp format_percentage(decimal) when is_struct(decimal, Decimal) do
    decimal |> Decimal.round(1) |> Decimal.to_string()
  end
  defp format_percentage(_), do: "0.0"

  defp calculate_percentage(amount, total) do
    if Decimal.gt?(total, Decimal.new("0")) do
      Decimal.mult(Decimal.div(amount, total), Decimal.new("100"))
    else
      Decimal.new("0")
    end
  end

  defp alert_severity_class("high"), do: "bg-red-800 text-red-100"
  defp alert_severity_class("medium"), do: "bg-yellow-800 text-yellow-100"
  defp alert_severity_class("low"), do: "bg-blue-800 text-blue-100"
  defp alert_severity_class(_), do: "bg-gray-800 text-gray-100"

  defp performance_status_class("over_budget"), do: "bg-red-800 text-red-100"
  defp performance_status_class("on_budget"), do: "bg-green-800 text-green-100"
  defp performance_status_class("under_budget"), do: "bg-blue-800 text-blue-100"
  defp performance_status_class(_), do: "bg-gray-800 text-gray-100"

  defp format_status("over_budget"), do: "Over Budget"
  defp format_status("on_budget"), do: "On Budget"
  defp format_status("under_budget"), do: "Under Budget"
  defp format_status(status), do: String.capitalize(status)

  defp variance_color(variance) do
    cond do
      Decimal.gt?(variance, Decimal.new("0")) -> "text-green-400"
      Decimal.lt?(variance, Decimal.new("0")) -> "text-red-400"
      true -> "text-gray-400"
    end
  end

  defp format_variance(variance) do
    if Decimal.gt?(variance, Decimal.new("0")) do
      "+" <> format_currency(variance)
    else
      format_currency(variance)
    end
  end

  defp priority_class("high"), do: "bg-red-800 text-red-100"
  defp priority_class("medium"), do: "bg-yellow-800 text-yellow-100"
  defp priority_class("low"), do: "bg-green-800 text-green-100"
  defp priority_class(_), do: "bg-gray-800 text-gray-100"
end
