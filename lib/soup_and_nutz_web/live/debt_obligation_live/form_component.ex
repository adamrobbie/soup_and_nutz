defmodule SoupAndNutzWeb.DebtObligationLive.FormComponent do
  use SoupAndNutzWeb, :live_component

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.XBRL.Concepts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @page_title %>
        <:subtitle>Use this form to manage debt obligation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="debt_obligation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:debt_identifier]} type="text" label="Debt identifier" />
        <.input field={@form[:debt_name]} type="text" label="Debt name" />
        <.input field={@form[:debt_type]} type="select" label="Debt type" options={debt_type_options()} />
        <.input field={@form[:debt_category]} type="text" label="Debt category" />
        <.input field={@form[:principal_amount]} type="number" label="Principal amount" step="any" />
        <.input field={@form[:outstanding_balance]} type="number" label="Outstanding balance" step="any" />
        <.input field={@form[:interest_rate]} type="number" label="Interest rate" step="any" />
        <.input field={@form[:currency_code]} type="select" label="Currency code" options={currency_options()} />
        <.input field={@form[:issue_date]} type="date" label="Issue date" />
        <.input field={@form[:maturity_date]} type="date" label="Maturity date" />
        <.input field={@form[:next_payment_date]} type="date" label="Next payment date" />
        <.input field={@form[:payment_frequency]} type="select" label="Payment frequency" options={payment_frequency_options()} />
        <.input field={@form[:reporting_period]} type="text" label="Reporting period" />
        <.input field={@form[:reporting_entity]} type="text" label="Reporting entity" />
        <.input field={@form[:reporting_scenario]} type="select" label="Reporting scenario" options={scenario_options()} />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:lender]} type="text" label="Lender" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <.input field={@form[:risk_level]} type="select" label="Risk level" options={risk_level_options()} />
        <.input field={@form[:collateral_type]} type="select" label="Collateral type" options={collateral_type_options()} />
        <.input field={@form[:validation_status]} type="select" label="Validation status" options={validation_status_options()} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Debt Obligation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{debt_obligation: debt_obligation} = assigns, socket) do
    changeset = FinancialInstruments.change_debt_obligation(debt_obligation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"debt_obligation" => debt_obligation_params}, socket) do
    changeset =
      socket.assigns.debt_obligation
      |> FinancialInstruments.change_debt_obligation(debt_obligation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"debt_obligation" => debt_obligation_params}, socket) do
    save_debt_obligation(socket, socket.assigns.action, debt_obligation_params)
  end

  defp save_debt_obligation(socket, :edit, debt_obligation_params) do
    case FinancialInstruments.update_debt_obligation(socket.assigns.debt_obligation, debt_obligation_params) do
      {:ok, debt_obligation} ->
        notify_parent({:saved, debt_obligation})

        {:noreply,
         socket
         |> put_flash(:info, "Debt obligation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_debt_obligation(socket, :new, debt_obligation_params) do
    case FinancialInstruments.create_debt_obligation(debt_obligation_params) do
      {:ok, debt_obligation} ->
        notify_parent({:saved, debt_obligation})

        {:noreply,
         socket
         |> put_flash(:info, "Debt obligation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp debt_type_options do
    Concepts.debt_types()
    |> Enum.map(fn type -> {type, type} end)
  end

  defp currency_options do
    Concepts.currency_codes()
    |> Enum.map(fn code -> {code, code} end)
  end

  defp payment_frequency_options do
    Concepts.payment_frequencies()
    |> Enum.map(fn freq -> {freq, freq} end)
  end

  defp scenario_options do
    Concepts.scenario_types()
    |> Enum.map(fn scenario -> {scenario, scenario} end)
  end

  defp risk_level_options do
    Concepts.risk_levels()
    |> Enum.map(fn level -> {level, level} end)
  end

  defp collateral_type_options do
    Concepts.collateral_types()
    |> Enum.map(fn type -> {type, type} end)
  end

  defp validation_status_options do
    Concepts.validation_statuses()
    |> Enum.map(fn status -> {status, status} end)
  end
end
