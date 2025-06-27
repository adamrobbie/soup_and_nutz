defmodule SoupAndNutzWeb.DebtObligationLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.DebtObligation
  import SoupAndNutzWeb.FinancialHelpers

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:debt_obligations, list_debt_obligations(socket.assigns.current_user.id))
     |> assign(:filter_form, to_form(%{"debt_type" => "", "risk_level" => ""}))
     |> assign(:search_form, to_form(%{"query" => ""}))
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Debt Obligations")
    |> assign(:debt_obligation, nil)
    |> assign(:patch, ~p"/debt_obligations")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Debt Obligation")
    |> assign(:debt_obligation, %DebtObligation{})
    |> assign(:patch, ~p"/debt_obligations")
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Debt Obligation")
    |> assign(:debt_obligation, FinancialInstruments.get_debt_obligation!(id))
    |> assign(:patch, ~p"/debt_obligations")
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Debt Obligation")
    |> assign(:debt_obligation, FinancialInstruments.get_debt_obligation!(id))
    |> assign(:patch, ~p"/debt_obligations")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    debt_obligation = FinancialInstruments.get_debt_obligation!(id)
    {:ok, _} = FinancialInstruments.delete_debt_obligation(debt_obligation)

    {:noreply, assign(socket, :debt_obligations, list_debt_obligations(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("filter", %{"debt_type" => debt_type, "risk_level" => risk_level}, socket) do
    filtered_debts = list_debt_obligations(socket.assigns.current_user.id)
    |> Enum.filter(fn debt ->
      (debt_type == "" or debt.debt_type == debt_type) and
      (risk_level == "" or debt.risk_level == risk_level)
    end)

    {:noreply, assign(socket, :debt_obligations, filtered_debts)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_debts = if query == "" do
      list_debt_obligations(socket.assigns.current_user.id)
    else
      list_debt_obligations(socket.assigns.current_user.id)
      |> Enum.filter(fn debt ->
        String.contains?(String.downcase(debt.debt_name || ""), String.downcase(query))
      end)
    end

    {:noreply, assign(socket, :debt_obligations, filtered_debts)}
  end

  defp list_debt_obligations(user_id) do
    FinancialInstruments.list_debt_obligations_by_user(user_id)
  end

  def debt_type_options do
    [
      {"All Types", ""},
      {"Short Term Debt", "ShortTermDebt"},
      {"Long Term Debt", "LongTermDebt"},
      {"Mortgage", "Mortgage"},
      {"Credit Card", "CreditCard"},
      {"Student Loan", "StudentLoan"},
      {"Auto Loan", "AutoLoan"},
      {"Personal Loan", "PersonalLoan"},
      {"Business Loan", "BusinessLoan"},
      {"Line of Credit", "LineOfCredit"},
      {"Bond", "Bond"},
      {"Lease Obligation", "LeaseObligation"},
      {"Accounts Payable", "AccountsPayable"},
      {"Accrued Expenses", "AccruedExpenses"},
      {"Deferred Revenue", "DeferredRevenue"},
      {"Pension Obligations", "PensionObligations"},
      {"Other Debt", "OtherDebt"}
    ]
  end

  def risk_level_options do
    [
      {"All Levels", ""},
      {"Low", "Low"},
      {"Medium", "Medium"},
      {"High", "High"}
    ]
  end

  # Helper functions for formatting and calculations

  def total_outstanding_debt(debts) do
    debts
    |> Enum.reduce(Decimal.new(0), fn debt, acc ->
      balance = debt.outstanding_balance || Decimal.new(0)
      Decimal.add(acc, balance)
    end)
  end

  def total_monthly_payments(debts) do
    debts
    |> Enum.reduce(Decimal.new(0), fn debt, acc ->
      payment = debt.monthly_payment || Decimal.new(0)
      Decimal.add(acc, payment)
    end)
  end

  def average_interest_rate(debts) do
    case debts do
      [] -> Decimal.new(0)
      _ ->
        total_rate = debts
        |> Enum.reduce(Decimal.new(0), fn debt, acc ->
          rate = debt.interest_rate || Decimal.new(0)
          Decimal.add(acc, rate)
        end)
        Decimal.div(total_rate, Decimal.new(length(debts)))
    end
  end

  def format_date(date) do
    case date do
      nil -> "N/A"
      date when is_struct(date, Date) ->
        Calendar.strftime(date, "%Y-%m-%d")
      _ -> "N/A"
    end
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
