defmodule SoupAndNutzWeb.AssetLive.Index do
  use SoupAndNutzWeb, :live_view

  alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.FinancialInstruments.Asset
  import SoupAndNutzWeb.FinancialHelpers

  on_mount {SoupAndNutzWeb.Live.AuthHook, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:assets, list_assets(socket.assigns.current_user.id))
     |> assign(:filter_form, to_form(%{"asset_type" => "", "risk_level" => ""}))
     |> assign(:search_form, to_form(%{"query" => ""}))
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Assets")
    |> assign(:asset, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, FinancialInstruments.get_asset!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Asset")
    |> assign(:asset, FinancialInstruments.get_asset!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset = FinancialInstruments.get_asset!(id)
    {:ok, _} = FinancialInstruments.delete_asset(asset)

    {:noreply, assign(socket, :assets, list_assets(socket.assigns.current_user.id))}
  end

  @impl true
  def handle_event("filter", %{"asset_type" => asset_type, "risk_level" => risk_level}, socket) do
    filtered_assets = list_assets(socket.assigns.current_user.id)
    |> Enum.filter(fn asset ->
      (asset_type == "" or asset.asset_type == asset_type) and
      (risk_level == "" or asset.risk_level == risk_level)
    end)

    {:noreply, assign(socket, :assets, filtered_assets)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_assets = if query == "" do
      list_assets(socket.assigns.current_user.id)
    else
      list_assets(socket.assigns.current_user.id)
      |> Enum.filter(fn asset ->
        String.contains?(String.downcase(asset.asset_name || ""), String.downcase(query))
      end)
    end

    {:noreply, assign(socket, :assets, filtered_assets)}
  end

  defp list_assets(user_id) do
    FinancialInstruments.list_assets_by_user(user_id)
  end

  def asset_type_options do
    [
      {"Investment Securities", "InvestmentSecurities"},
      {"Real Estate", "RealEstate"},
      {"Cash and Cash Equivalents", "CashAndCashEquivalents"},
      {"Intangible Assets", "IntangibleAssets"},
      {"Other Assets", "OtherAssets"}
    ]
  end

  def risk_level_options do
    [
      {"Low", "Low"},
      {"Medium", "Medium"},
      {"High", "High"}
    ]
  end

  def liquidity_level_options do
    [
      {"High", "High"},
      {"Medium", "Medium"},
      {"Low", "Low"}
    ]
  end

  def total_asset_value(assets) do
    SoupAndNutz.FinancialInstruments.Asset.total_fair_value(assets)
  end

  def average_risk_level(assets) do
    risk_levels = Enum.map(assets, & &1.risk_level)

    if Enum.empty?(risk_levels) do
      "N/A"
    else
      calculate_average_risk(risk_levels)
    end
  end

  defp calculate_average_risk(risk_levels) do
    levels = %{"Low" => 1, "Medium" => 2, "High" => 3}

    nums =
      risk_levels
      |> Enum.map(&Map.get(levels, &1, 0))
      |> Enum.reject(&(&1 == 0))

    avg = if Enum.empty?(nums), do: 0, else: Enum.sum(nums) / length(nums)

    cond do
      avg < 1.5 -> "Low"
      avg < 2.5 -> "Medium"
      avg >= 2.5 -> "High"
      true -> "N/A"
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
