defmodule SoupAndNutzWeb.CashFlowLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.CashFlow
  import SoupAndNutzWeb.FinancialHelpers

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    cash_flows = FinancialInstruments.list_cash_flows_by_user(socket.assigns.current_user.id)
    {:ok,
     socket
     |> stream(:cash_flows, cash_flows)
     |> assign(:cash_flows, cash_flows)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Cash flow")
    |> assign(:cash_flow, FinancialInstruments.get_cash_flow!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Cash flow")
    |> assign(:cash_flow, %CashFlow{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Cash flows")
    |> assign(:cash_flow, nil)
  end

  @impl true
  def handle_info({SoupAndNutzWeb.CashFlowLive.FormComponent, {:saved, cash_flow}}, socket) do
    updated_cash_flows = FinancialInstruments.list_cash_flows_by_user(socket.assigns.current_user.id)
    {:noreply,
     socket
     |> stream_insert(:cash_flows, cash_flow)
     |> assign(:cash_flows, updated_cash_flows)
    }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cash_flow = FinancialInstruments.get_cash_flow!(id)
    {:ok, _} = FinancialInstruments.delete_cash_flow(cash_flow)

    updated_cash_flows = FinancialInstruments.list_cash_flows_by_user(socket.assigns.current_user.id)
    {:noreply,
     socket
     |> stream_delete(:cash_flows, cash_flow)
     |> assign(:cash_flows, updated_cash_flows)
    }
  end

  def total_cash_inflow(cash_flows) do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == "Income"))
    |> Enum.reduce(Decimal.new(0), fn cf, acc -> Decimal.add(acc, cf.amount) end)
  end

  def total_cash_outflow(cash_flows) do
    cash_flows
    |> Enum.filter(&(&1.cash_flow_type == "Expense"))
    |> Enum.reduce(Decimal.new(0), fn cf, acc -> Decimal.add(acc, cf.amount) end)
  end

  def net_cash_flow(cash_flows) do
    Decimal.sub(total_cash_inflow(cash_flows), total_cash_outflow(cash_flows))
  end

  def format_datetime(datetime) do
    case datetime do
      nil -> "N/A"
      datetime when is_struct(datetime, DateTime) ->
        Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
      _ -> "N/A"
    end
  end
end
