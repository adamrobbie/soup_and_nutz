defmodule SoupAndNutzWeb.CashFlowForecastLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialAnalysis

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @default_months 12

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    period = Date.utc_today() |> Date.to_iso8601() |> String.slice(0, 7) # "YYYY-MM"
    currency = "USD"
    months = @default_months

    forecast = FinancialAnalysis.analyze_cash_flow_impact(user_id, period, currency, months)

    # Generate monthly forecast data (simple projection: current net cash flow * month)
    monthly_net = forecast.monthly_net_cash_flow
    monthly_data = Enum.map(1..months, fn m ->
      %{month: m, net_cash_flow: monthly_net, cumulative: Decimal.mult(monthly_net, Decimal.new(m))}
    end)

    # Calculate runway (months until cash runs out, if negative net cash flow)
    # For demo, assume starting cash = 0 (could be improved by using actual cash balance)
    runway = if Decimal.cmp(monthly_net, 0) == :lt do
      "∞"
    else
      "N/A"
    end

    socket =
      socket
      |> assign(:page_title, "Cash Flow Forecast & Burn Rate")
      |> assign(:forecast, forecast)
      |> assign(:months, months)
      |> assign(:monthly_data, monthly_data)
      |> assign(:runway, runway)
      |> assign(:chart_data, Jason.encode!(%{
        labels: Enum.map(1..months, &"Month #{&1}"),
        data: Enum.map(monthly_data, & &1.net_cash_flow)
      }))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4">Cash Flow Forecast & Burn Rate</h1>
      <div class="mb-6">
        <p class="text-gray-300">Monthly Net Cash Flow: <span class={if Decimal.cmp(@forecast.monthly_net_cash_flow, 0) == :lt, do: "text-red-400", else: "text-green-400"}><%= @forecast.monthly_net_cash_flow %></span></p>
        <p class="text-gray-300">Runway (months until cash runs out): <%= @runway %></p>
      </div>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-2">Forecast Chart</h2>
        <canvas id="cashFlowForecastChart" phx-hook="CashFlowForecastChart" class="w-full h-64 bg-gray-800 rounded"></canvas>
      </div>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-2">Monthly Forecast Table</h2>
        <table class="min-w-full bg-gray-900 text-gray-200 rounded-lg overflow-hidden">
          <thead>
            <tr>
              <th class="px-4 py-2">Month</th>
              <th class="px-4 py-2">Net Cash Flow</th>
              <th class="px-4 py-2">Cumulative</th>
            </tr>
          </thead>
          <tbody>
            <%= for row <- @monthly_data do %>
              <tr>
                <td class="border px-4 py-2"><%= row.month %></td>
                <td class="border px-4 py-2"><%= row.net_cash_flow %></td>
                <td class="border px-4 py-2"><%= row.cumulative %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      <div>
        <h2 class="text-lg font-semibold mb-2">Expense Breakdown</h2>
        <ul class="list-disc ml-6 text-gray-200">
          <%= for {category, %{total: total}} <- @forecast.expense_breakdown do %>
            <li><%= category %>: <%= total %></li>
          <% end %>
        </ul>
      </div>
      <script>
        window.cashFlowForecastChartData = <%= raw @chart_data %>;
      </script>
    </div>
    """
  end
end
