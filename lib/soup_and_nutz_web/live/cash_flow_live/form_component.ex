defmodule SoupAndNutzWeb.CashFlowLive.FormComponent do
  use SoupAndNutzWeb, :live_component

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.XBRL.Concepts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage cash flow records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="cash_flow-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:amount]} type="number" label="Amount" step="0.01" />
        <.input field={@form[:flow_type]} type="select" label="Flow type" options={flow_type_options()} />
        <.input field={@form[:category]} type="select" label="Category" options={category_options()} />
        <.input field={@form[:frequency]} type="select" label="Frequency" options={frequency_options()} />
        <.input field={@form[:start_date]} type="date" label="Start date" />
        <.input field={@form[:end_date]} type="date" label="End date" />
        <.input field={@form[:entity_id]} type="text" label="Entity" />
        <.input field={@form[:notes]} type="textarea" label="Notes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Cash flow</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cash_flow: cash_flow} = assigns, socket) do
    changeset = FinancialInstruments.change_cash_flow(cash_flow)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cash_flow" => cash_flow_params}, socket) do
    changeset =
      socket.assigns.cash_flow
      |> FinancialInstruments.change_cash_flow(cash_flow_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"cash_flow" => cash_flow_params}, socket) do
    save_cash_flow(socket, socket.assigns.action, cash_flow_params)
  end

  defp save_cash_flow(socket, :edit, cash_flow_params) do
    case FinancialInstruments.update_cash_flow(socket.assigns.cash_flow, cash_flow_params) do
      {:ok, cash_flow} ->
        notify_parent({:saved, cash_flow})

        {:noreply,
         socket
         |> put_flash(:info, "Cash flow updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_cash_flow(socket, :new, cash_flow_params) do
    cash_flow_params_with_user = Map.put(cash_flow_params, "user_id", socket.assigns.current_user.id)

    case FinancialInstruments.create_cash_flow(cash_flow_params_with_user) do
      {:ok, cash_flow} ->
        notify_parent({:saved, cash_flow})

        {:noreply,
         socket
         |> put_flash(:info, "Cash flow created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp flow_type_options do
    Concepts.cash_flow_types()
    |> Enum.map(fn {key, value} -> {value, key} end)
  end

  defp category_options do
    Concepts.cash_flow_categories()
    |> Enum.map(fn {key, value} -> {value, key} end)
  end

  defp frequency_options do
    Concepts.cash_flow_frequencies()
    |> Enum.map(fn {key, value} -> {value, key} end)
  end
end
