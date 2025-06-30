defmodule SoupAndNutzWeb.DebtPayoffLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.{DebtPayoffPlanner, FinancialInstruments}
  alias SoupAndNutz.FinancialInstruments.DebtObligation

  # Add auth hook to ensure current_user is set
  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @default_extra_payments [0, 50, 100, 200, 500]

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id  # Get from current_user instead of hardcoding
    debts = FinancialInstruments.list_debt_obligations_by_user(user_id)
    extra_payments = @default_extra_payments
    extra_payment_input = Enum.join(extra_payments, ", ")
    extra_payment_analysis = DebtPayoffPlanner.analyze_extra_payment_impact(debts, extra_payments)
    strategy_comparison = DebtPayoffPlanner.compare_strategies(debts)
    consolidation_rate = Decimal.new("7.5")
    consolidation_term = 60
    consolidation_results = nil

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:debts, debts)
      |> assign(:strategy_comparison, strategy_comparison)
      |> assign(:extra_payment_analysis, extra_payment_analysis)
      |> assign(:extra_payment_input, extra_payment_input)
      |> assign(:selected_strategy, "avalanche")
      |> assign(:show_consolidation, false)
      |> assign(:consolidation_rate, consolidation_rate)
      |> assign(:consolidation_term, consolidation_term)
      |> assign(:consolidation_results, consolidation_results)
      |> assign(:page_title, "Debt Payoff Planner")

    {:ok, socket}
  end

  @impl true
  def handle_event("change_strategy", %{"strategy" => strategy}, socket) do
    socket = assign(socket, :selected_strategy, strategy)
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_extra_payments", %{"extra_payments" => input}, socket) do
    # Parse comma-separated input into a list of decimals
    extra_payments =
      input
      |> String.split([",", ";", " "], trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(fn s ->
        case Decimal.parse(s) do
          {d, _} -> d
          _ -> Decimal.new("0")
        end
      end)
      |> Enum.uniq()
      |> Enum.sort()

    debts = socket.assigns.debts
    extra_payment_analysis = DebtPayoffPlanner.analyze_extra_payment_impact(debts, extra_payments)
    socket = assign(socket, :extra_payment_analysis, extra_payment_analysis)
    socket = assign(socket, :extra_payment_input, input)
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_consolidation", _params, socket) do
    debts = socket.assigns.debts
    rate = socket.assigns.consolidation_rate
    term = socket.assigns.consolidation_term

    consolidation_results = DebtPayoffPlanner.analyze_consolidation_options(debts, rate, term)

    socket =
      socket
      |> assign(:show_consolidation, true)
      |> assign(:consolidation_results, consolidation_results)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_consolidation_rate", %{"rate" => rate_str}, socket) do
    rate = case Decimal.parse(rate_str) do
      {decimal, _} -> decimal
      _ -> Decimal.new("7.5")
    end

    debts = socket.assigns.debts
    term = socket.assigns.consolidation_term

    consolidation_results = DebtPayoffPlanner.analyze_consolidation_options(debts, rate, term)

    socket =
      socket
      |> assign(:consolidation_rate, rate)
      |> assign(:consolidation_results, consolidation_results)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_consolidation_term", %{"term" => term_str}, socket) do
    term = case Integer.parse(term_str) do
      {int, _} -> int
      :error -> 60
    end

    debts = socket.assigns.debts
    rate = socket.assigns.consolidation_rate

    consolidation_results = DebtPayoffPlanner.analyze_consolidation_options(debts, rate, term)

    socket =
      socket
      |> assign(:consolidation_term, term)
      |> assign(:consolidation_results, consolidation_results)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-black min-h-screen">
      <div class="px-6 py-8">
        <!-- Page Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-white">Debt Payoff Planner</h1>
          <p class="text-gray-400 mt-2">Compare debt payoff strategies and optimize your path to debt freedom</p>
        </div>

        <!-- Debt Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-red-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-red-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Total Debt</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_currency(total_outstanding_debt(@debts)) %>
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-yellow-900 rounded-md flex items-center justify-center">
                  <span class="text-yellow-300 font-bold">%</span>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Avg Interest Rate</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_percentage(average_interest_rate(@debts)) %>%
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-purple-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-purple-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Monthly Payments</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= format_currency(total_monthly_payments(@debts)) %>
                </dd>
              </div>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 bg-green-900 rounded-md flex items-center justify-center">
                  <svg class="w-5 h-5 text-green-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </div>
              </div>
              <div class="ml-5">
                <dt class="text-sm font-medium text-gray-400">Debt Count</dt>
                <dd class="text-xl font-semibold text-white">
                  <%= length(@debts) %>
                </dd>
              </div>
            </div>
          </div>
        </div>

        <!-- Strategy Selection -->
        <div class="mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-4">Payoff Strategy</h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <%= for {strategy, description} <- strategy_options() do %>
                <button
                  phx-click="change_strategy"
                  phx-value-strategy={strategy}
                  class={[
                    "p-4 rounded-lg border text-left transition-colors",
                    if(@selected_strategy == strategy,
                      do: "border-blue-500 bg-blue-900 text-blue-100",
                      else: "border-gray-700 bg-gray-800 text-gray-300 hover:border-gray-600")
                  ]}
                >
                  <div class="font-medium"><%= strategy_name(strategy) %></div>
                  <div class="text-sm opacity-75 mt-1"><%= description %></div>
                </button>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Strategy Comparison -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-white mb-4">Strategy Comparison</h3>
            <div class="space-y-4">
              <%= for strategy <- @strategy_comparison.strategies do %>
                <div class={[
                  "p-4 rounded-lg border",
                  if(@selected_strategy == String.downcase(strategy.name),
                    do: "border-blue-500 bg-blue-900",
                    else: "border-gray-700 bg-gray-800")
                ]}>
                  <div class="flex items-center justify-between mb-2">
                    <h4 class="font-medium text-white"><%= strategy.name %></h4>
                    <%= if strategy.name == @strategy_comparison.best_financial.name do %>
                      <span class="text-xs px-2 py-1 bg-green-800 text-green-100 rounded-full">
                        Best Value
                      </span>
                    <% end %>
                  </div>
                  <p class="text-gray-300 text-sm mb-3"><%= strategy.description %></p>
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="text-gray-400">Total Interest:</span>
                      <div class="text-white font-medium">
                        <%= format_currency(strategy.data.total_interest_paid) %>
                      </div>
                    </div>
                    <div>
                      <span class="text-gray-400">Payoff Time:</span>
                      <div class="text-white font-medium">
                        <%= strategy.data.total_months_to_payoff %> months
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-white mb-4">Extra Payment Impact</h3>
            <div class="space-y-4">
              <%= for scenario <- @extra_payment_analysis.extra_payment_scenarios do %>
                <div class="p-4 bg-gray-800 rounded-lg">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-white font-medium">
                      +<%= format_currency(scenario.extra_payment) %>/month
                    </span>
                    <%= if scenario.extra_payment == @extra_payment_analysis.recommended_extra_payment.extra_payment do %>
                      <span class="text-xs px-2 py-1 bg-blue-800 text-blue-100 rounded-full">
                        Recommended
                      </span>
                    <% end %>
                  </div>
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="text-gray-400">Time Saved:</span>
                      <div class="text-green-400 font-medium">
                        <%= scenario.months_saved %> months
                      </div>
                    </div>
                    <div>
                      <span class="text-gray-400">Interest Saved:</span>
                      <div class="text-green-400 font-medium">
                        <%= format_currency(scenario.interest_saved) %>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Selected Strategy Details -->
        <div class="mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-white mb-4">
              <%= strategy_name(@selected_strategy) %> Strategy Details
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div>
                <h4 class="text-md font-medium text-white mb-3">Payoff Order</h4>
                <div class="space-y-2">
                  <%= for {debt, index} <- Enum.with_index(@debts) do %>
                    <div class="flex items-center justify-between bg-gray-800 rounded p-3">
                      <div class="flex items-center">
                        <div class="w-6 h-6 bg-blue-600 rounded-full flex items-center justify-center text-white text-xs font-medium mr-3">
                          <%= index + 1 %>
                        </div>
                        <div>
                          <div class="text-white text-sm font-medium"><%= debt.debt_name %></div>
                          <div class="text-gray-400 text-xs"><%= format_currency(debt.outstanding_balance) %></div>
                        </div>
                      </div>
                      <div class="text-right">
                        <div class="text-gray-300 text-sm"><%= format_percentage(debt.interest_rate) %>%</div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>

              <div>
                <h4 class="text-md font-medium text-white mb-3">Summary</h4>
                <div class="space-y-3">
                  <div class="flex justify-between">
                    <span class="text-gray-300">Total Debt:</span>
                    <span class="text-white"><%= format_currency(total_outstanding_debt(@debts)) %></span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-300">Monthly Payments:</span>
                    <span class="text-white"><%= format_currency(total_monthly_payments(@debts)) %></span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-300">Current Strategy:</span>
                    <span class="text-blue-400"><%= strategy_name(@selected_strategy) %></span>
                  </div>
                </div>
              </div>

              <div>
                <h4 class="text-md font-medium text-white mb-3">Projections</h4>
                <div class="space-y-3">
                  <div class="flex justify-between">
                    <span class="text-gray-300">Payoff Time:</span>
                    <span class="text-white">
                      <%= get_strategy_data(@strategy_comparison, @selected_strategy).total_months_to_payoff %> months
                    </span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-300">Total Interest:</span>
                    <span class="text-red-400">
                      <%= format_currency(get_strategy_data(@strategy_comparison, @selected_strategy).total_interest_paid) %>
                    </span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-gray-300">Total Payments:</span>
                    <span class="text-white">
                      <%= format_currency(get_strategy_data(@strategy_comparison, @selected_strategy).total_monthly_payments) %>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Interactive Extra Payment Scenario Modeling -->
        <div class="mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <h2 class="text-xl font-semibold text-white mb-4">Extra Payment Scenarios</h2>
            <form phx-change="change_extra_payments" class="mb-6">
              <label class="block text-sm font-medium text-gray-300 mb-2">
                Try different extra monthly payments (comma-separated):
              </label>
              <input
                type="text"
                name="extra_payments"
                value={@extra_payment_input}
                phx-debounce="400"
                class="w-full px-3 py-2 rounded border border-gray-600 bg-gray-800 text-white text-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder="e.g. 0, 50, 100, 200, 500"
              />
            </form>
            <div class="overflow-x-auto">
              <table class="min-w-full bg-gray-900 border border-gray-800 rounded-lg shadow">
                <thead class="text-xs text-gray-400 uppercase">
                  <tr>
                    <th class="px-4 py-2 font-normal">Extra Payment</th>
                    <th class="px-4 py-2 font-normal">Payoff Time</th>
                    <th class="px-4 py-2 font-normal">Interest Saved</th>
                    <th class="px-4 py-2 font-normal">Total Interest</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for scenario <- @extra_payment_analysis.extra_payment_scenarios do %>
                    <tr class={if scenario == @extra_payment_analysis.recommended_extra_payment, do: "bg-blue-900 text-blue-100", else: ""}>
                      <td class="px-4 py-2 font-mono">
                        <%= format_currency(scenario.extra_payment) %>/mo
                        <%= if scenario == @extra_payment_analysis.recommended_extra_payment do %>
                          <span class="ml-2 text-xs bg-blue-800 text-blue-100 px-2 py-0.5 rounded-full">Best ROI</span>
                        <% end %>
                      </td>
                      <td class="px-4 py-2">
                        <span class="font-semibold text-white"><%= scenario.total_months %></span> months
                        <%= if scenario.months_saved > 0 do %>
                          <span class="ml-2 text-green-400 text-xs">-<%= scenario.months_saved %> mo</span>
                        <% end %>
                      </td>
                      <td class="px-4 py-2">
                        <span class="font-semibold text-green-400"><%= format_currency(scenario.interest_saved) %></span>
                      </td>
                      <td class="px-4 py-2">
                        <span class="text-white"><%= format_currency(scenario.total_interest) %></span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Consolidation Analysis -->
        <div class="mb-8">
          <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-white">Debt Consolidation Analysis</h3>
              <button
                phx-click="show_consolidation"
                class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Analyze Consolidation
              </button>
            </div>

            <%= if @show_consolidation and @consolidation_results do %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h4 class="text-md font-medium text-white mb-3">Consolidation Options</h4>
                  <div class="space-y-4">
                    <div class="flex items-center space-x-4">
                      <label class="text-gray-300 text-sm">Interest Rate:</label>
                      <input
                        type="number"
                        step="0.1"
                        min="0"
                        max="30"
                        value={Decimal.to_string(@consolidation_rate)}
                        phx-blur="update_consolidation_rate"
                        phx-value-rate={Decimal.to_string(@consolidation_rate)}
                        class="w-20 px-2 py-1 border border-gray-600 bg-gray-800 text-white text-sm rounded"
                      />
                      <span class="text-gray-300 text-sm">%</span>
                    </div>
                    <div class="flex items-center space-x-4">
                      <label class="text-gray-300 text-sm">Term:</label>
                      <input
                        type="number"
                        min="12"
                        max="360"
                        value={@consolidation_term}
                        phx-blur="update_consolidation_term"
                        phx-value-term={@consolidation_term}
                        class="w-20 px-2 py-1 border border-gray-600 bg-gray-800 text-white text-sm rounded"
                      />
                      <span class="text-gray-300 text-sm">months</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 class="text-md font-medium text-white mb-3">Consolidation Benefits</h4>
                  <div class="space-y-3">
                    <div class="flex justify-between">
                      <span class="text-gray-300">Interest Savings:</span>
                      <span class="text-green-400">
                        <%= format_currency(@consolidation_results.savings.interest_savings) %>
                      </span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-300">Monthly Payment:</span>
                      <span class="text-white">
                        <%= format_currency(@consolidation_results.consolidation_scenario.monthly_payment) %>
                      </span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-gray-300">Time Saved:</span>
                      <span class="text-green-400">
                        <%= @consolidation_results.savings.time_difference %> months
                      </span>
                    </div>
                    <div class="mt-4 p-3 bg-gray-800 rounded">
                      <div class="text-sm font-medium text-white mb-1">Recommendation:</div>
                      <div class="text-gray-300 text-sm"><%= @consolidation_results.recommendation %></div>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Recommendation -->
        <div class="bg-gray-900 border border-gray-800 rounded-lg p-6">
          <h3 class="text-lg font-semibold text-white mb-4">Recommendation</h3>
          <div class="bg-blue-900 border border-blue-800 rounded-lg p-4">
            <p class="text-blue-100">
              <%= @strategy_comparison.recommendation %>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp strategy_options do
    [
      {"avalanche", "Pay highest interest rates first - saves the most money"},
      {"snowball", "Pay smallest balances first - provides psychological wins"},
      {"custom", "Pay based on your priority levels"}
    ]
  end

  defp strategy_name("avalanche"), do: "Avalanche"
  defp strategy_name("snowball"), do: "Snowball"
  defp strategy_name("custom"), do: "Custom Priority"
  defp strategy_name(strategy), do: String.capitalize(strategy)

  defp format_currency(decimal) when is_struct(decimal, Decimal) do
    "$" <> (decimal |> Decimal.round(2) |> Decimal.to_string())
  end
  defp format_currency(_), do: "$0.00"

  defp format_percentage(decimal) when is_struct(decimal, Decimal) do
    decimal |> Decimal.round(2) |> Decimal.to_string()
  end
  defp format_percentage(_), do: "0.00"

  defp total_outstanding_debt(debts) do
    DebtObligation.total_outstanding_debt(debts)
  end

  defp total_monthly_payments(debts) do
    DebtObligation.total_monthly_payments(debts)
  end

  defp average_interest_rate(debts) do
    if length(debts) > 0 do
      total_balance = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
        Decimal.add(acc, debt.outstanding_balance)
      end)

      if Decimal.gt?(total_balance, Decimal.new("0")) do
        weighted_sum = Enum.reduce(debts, Decimal.new("0"), fn debt, acc ->
          weight = Decimal.mult(debt.outstanding_balance, debt.interest_rate)
          Decimal.add(acc, weight)
        end)

        Decimal.div(weighted_sum, total_balance)
      else
        Decimal.new("0")
      end
    else
      Decimal.new("0")
    end
  end

  defp get_strategy_data(strategy_comparison, strategy_name) do
    Enum.find(strategy_comparison.strategies, fn strategy ->
      String.downcase(strategy.name) == strategy_name
    end).data
  end
end
