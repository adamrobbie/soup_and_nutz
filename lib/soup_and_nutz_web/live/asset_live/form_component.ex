defmodule SoupAndNutzWeb.AssetLive.FormComponent do
  use SoupAndNutzWeb, :live_component

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.XBRL.Concepts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:asset_identifier]} type="text" label="Asset identifier" />
        <.input field={@form[:asset_name]} type="text" label="Asset name" />
        <.input field={@form[:asset_type]} type="select" label="Asset type" options={asset_type_options()} />
        <.input field={@form[:asset_category]} type="text" label="Asset category" />
        <.input field={@form[:fair_value]} type="number" label="Fair value" step="0.01" />
        <.input field={@form[:book_value]} type="number" label="Book value" step="0.01" />
        <.input field={@form[:currency_code]} type="text" label="Currency code" />
        <.input field={@form[:measurement_date]} type="date" label="Measurement date" />
        <.input field={@form[:reporting_period]} type="text" label="Reporting period" />
        <.input field={@form[:reporting_scenario]} type="text" label="Reporting scenario" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:custodian]} type="text" label="Custodian" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <.input field={@form[:risk_level]} type="select" label="Risk level" options={risk_level_options()} />
        <.input field={@form[:liquidity_level]} type="select" label="Liquidity level" options={liquidity_level_options()} />
        <.input field={@form[:validation_status]} type="select" label="Validation status" options={validation_status_options()} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Asset</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    changeset = FinancialInstruments.change_asset(asset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      socket.assigns.asset
      |> FinancialInstruments.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    case FinancialInstruments.update_asset(socket.assigns.asset, asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_asset(socket, :new, asset_params) do
    asset_params_with_user = Map.put(asset_params, "user_id", socket.assigns.current_user.id)

    case FinancialInstruments.create_asset(asset_params_with_user) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp asset_type_options do
    Concepts.asset_types()
    |> Enum.map(fn type -> {type, type} end)
  end

  defp risk_level_options do
    Concepts.risk_levels()
    |> Enum.map(fn level -> {level, level} end)
  end

  defp liquidity_level_options do
    Concepts.liquidity_levels()
    |> Enum.map(fn level -> {level, level} end)
  end

  defp validation_status_options do
    Concepts.validation_statuses()
    |> Enum.map(fn status -> {status, status} end)
  end
end
