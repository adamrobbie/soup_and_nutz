defmodule SoupAndNutzWeb.DebtObligationLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.DebtObligation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :debt_obligations, list_debt_obligations())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Debt Obligations")
    |> assign(:debt_obligation, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Debt Obligation")
    |> assign(:debt_obligation, %DebtObligation{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Debt Obligation")
    |> assign(:debt_obligation, FinancialInstruments.get_debt_obligation!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Debt Obligation")
    |> assign(:debt_obligation, FinancialInstruments.get_debt_obligation!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    debt_obligation = FinancialInstruments.get_debt_obligation!(id)
    {:ok, _} = FinancialInstruments.delete_debt_obligation(debt_obligation)

    {:noreply, assign(socket, :debt_obligations, list_debt_obligations())}
  end

  defp list_debt_obligations do
    FinancialInstruments.list_debt_obligations()
  end
end
