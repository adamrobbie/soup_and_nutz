defmodule SoupAndNutzWeb.FinancialGoalLive.FormComponent do
  use SoupAndNutzWeb, :live_component

  alias SoupAndNutz.FinancialGoals

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage financial goals in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="financial_goal-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:goal_name]} type="text" label="Goal Name" />
        <.input field={@form[:goal_type]} type="select" label="Goal Type" options={goal_type_options()} />
        <.input field={@form[:target_amount]} type="number" label="Target Amount" step="0.01" />
        <.input field={@form[:current_amount]} type="number" label="Current Amount" step="0.01" />
        <.input field={@form[:target_date]} type="date" label="Target Date" />
        <.input field={@form[:start_date]} type="date" label="Start Date" />
        <.input field={@form[:priority_level]} type="select" label="Priority Level" options={priority_options()} />
        <.input field={@form[:goal_description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Financial Goal</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{financial_goal: financial_goal} = assigns, socket) do
    changeset = FinancialGoals.change_financial_goal(financial_goal)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"financial_goal" => financial_goal_params}, socket) do
    changeset =
      socket.assigns.financial_goal
      |> FinancialGoals.change_financial_goal(financial_goal_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"financial_goal" => financial_goal_params}, socket) do
    save_financial_goal(socket, socket.assigns.action, financial_goal_params)
  end

  defp save_financial_goal(socket, :edit, financial_goal_params) do
    case FinancialGoals.update_financial_goal(socket.assigns.financial_goal, financial_goal_params) do
      {:ok, financial_goal} ->
        notify_parent({:saved, financial_goal})

        {:noreply,
         socket
         |> put_flash(:info, "Financial goal updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_financial_goal(socket, :new, financial_goal_params) do
    financial_goal_params_with_user = Map.put(financial_goal_params, "user_id", socket.assigns.current_user.id)
    financial_goal_params_with_identifier = Map.put(financial_goal_params_with_user, "goal_identifier", "GOAL_#{System.system_time()}")

    case FinancialGoals.create_financial_goal(financial_goal_params_with_identifier) do
      {:ok, financial_goal} ->
        notify_parent({:saved, financial_goal})

        {:noreply,
         socket
         |> put_flash(:info, "Financial goal created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp goal_type_options do
    [
      {"Savings", "Savings"},
      {"Debt Payoff", "DebtPayoff"},
      {"Investment", "Investment"},
      {"Emergency Fund", "EmergencyFund"},
      {"Retirement", "Retirement"},
      {"Education", "Education"},
      {"Home Purchase", "HomePurchase"},
      {"Vehicle Purchase", "VehiclePurchase"},
      {"Travel", "Travel"},
      {"Business", "Business"},
      {"Other", "Other"}
    ]
  end

  defp priority_options do
    [
      {"Low", "Low"},
      {"Medium", "Medium"},
      {"High", "High"},
      {"Critical", "Critical"}
    ]
  end
end
