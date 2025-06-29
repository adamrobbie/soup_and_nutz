defmodule SoupAndNutzWeb.NetWorthProjectionLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialAnalysis

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @projection_periods [12, 24, 60]

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    period = Date.utc_today() |> Date.to_iso8601() |> String.slice(0, 7) # "YYYY-MM"
    currency = "USD"

    projections = Enum.map(@projection_periods, fn months ->
      result = FinancialAnalysis.calculate_net_worth(user_id, period, currency, months)
      {months, result.projected_net_worth}
    end)

    # Calculate growth rate (simple: (final - initial) / initial * 100)
    {first_months, first_value} = List.first(projections)
    {last_months, last_value} = List.last(projections)
    growth_rate =
      if Decimal.eq?(first_value, Decimal.new("0")) do
        Decimal.new("0")
      else
        Decimal.mult(Decimal.div(Decimal.sub(last_value, first_value), first_value), Decimal.new("100"))
      end

    chart_data = Jason.encode!(%{
      labels: Enum.map(projections, fn {months, _} -> "#{months} mo" end),
      data: Enum.map(projections, fn {_, value} -> value end)
    })

    socket =
      socket
      |> assign(:page_title, "Net Worth Projection")
      |> assign(:projections, projections)
      |> assign(:growth_rate, growth_rate)
      |> assign(:chart_data, chart_data)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold mb-4">Net Worth Projection</h1>
      <div class="mb-6">
        <p class="text-gray-300">Growth Rate (#{Enum.join(Enum.map(@projections, fn {months, _} -> "#{months}m" end), ", ")}):
          <span class={if Decimal.cmp(@growth_rate, 0) == :lt, do: "text-red-400", else: "text-green-400"}>
            <%= SoupAndNutzWeb.FinancialHelpers.format_percentage(@growth_rate) %>
          </span>
        </p>
      </div>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-2">Net Worth Projection Chart</h2>
        <canvas id="netWorthProjectionChart" phx-hook="NetWorthProjectionChart" class="w-full h-64 bg-gray-800 rounded"></canvas>
      </div>
      <div class="mb-8">
        <h2 class="text-lg font-semibold mb-2">Projection Table</h2>
        <table class="min-w-full bg-gray-900 text-gray-200 rounded-lg overflow-hidden">
          <thead>
            <tr>
              <th class="px-4 py-2">Projection Period (Months)</th>
              <th class="px-4 py-2">Projected Net Worth</th>
            </tr>
          </thead>
          <tbody>
            <%= for {months, value} <- @projections do %>
              <tr>
                <td class="border px-4 py-2"><%= months %></td>
                <td class="border px-4 py-2"><%= value %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      <script>
        window.netWorthProjectionChartData = <%= raw @chart_data %>;
      </script>
    </div>
    """
  end
end
