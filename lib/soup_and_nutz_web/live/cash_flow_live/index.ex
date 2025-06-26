defmodule SoupAndNutzWeb.CashFlowLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.CashFlow

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :cash_flows, FinancialInstruments.list_cash_flows())}
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
    {:noreply, stream_insert(socket, :cash_flows, cash_flow)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cash_flow = FinancialInstruments.get_cash_flow!(id)
    {:ok, _} = FinancialInstruments.delete_cash_flow(cash_flow)

    {:noreply, stream_delete(socket, :cash_flows, cash_flow)}
  end
end
