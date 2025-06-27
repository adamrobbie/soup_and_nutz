defmodule SoupAndNutzWeb.E2ECase do
  @moduledoc """
  This module defines the test case to be used by
  end-to-end tests that require browser automation.

  Such tests rely on `Hound` and also import other functionality
  to make it easier to build common data structures and interact
  with the web interface.
  """

  use ExUnit.CaseTemplate
  use Hound.Helpers

  using do
    quote do
      # Import Hound helpers
      use Hound.Helpers

      # Import test utilities
      import SoupAndNutzWeb.E2ECase
      import SoupAndNutz.DataCase, only: [setup_sandbox: 1]

      # Import factories
      import SoupAndNutz.Factory
    end
  end

  setup tags do
    # Setup database sandbox
    SoupAndNutz.DataCase.setup_sandbox(tags)

    # Start Hound session
    Hound.start_session(tags)

    on_exit(fn ->
      Hound.end_session(tags)
    end)

    {:ok, %{}}
  end

  # Authentication helpers
  def sign_in_user(user \\ nil) do
    user = user || insert(:user)

    navigate_to("/login")

    fill_field({:id, "user_email"}, user.email)
    fill_field({:id, "user_password"}, "password123")

    click({:css, "button[type='submit']"})

    # Wait for redirect
    wait_for_page_to_load()

    user
  end

  def sign_out_user do
    navigate_to("/logout")
    wait_for_page_to_load()
  end

  # Navigation helpers
  def wait_for_page_to_load do
    :timer.sleep(500)
  end

  def wait_for_element(selector, timeout \\ 5000) do
    wait_until(fn ->
      element_displayed?(selector)
    end, timeout)
  end

  def wait_for_text(text, timeout \\ 5000) do
    wait_until(fn ->
      page_source() =~ text
    end, timeout)
  end

  # Form helpers
  def fill_form(fields) do
    Enum.each(fields, fn {field_id, value} ->
      fill_field({:id, field_id}, value)
    end)
  end

  def submit_form do
    click({:css, "button[type='submit']"})
    wait_for_page_to_load()
  end

  # Asset management helpers
  def create_asset_via_ui(asset_attrs \\ %{}) do
    navigate_to("/assets")
    click({:css, "a[href='/assets/new']"})

    default_attrs = %{
      "asset_name" => "Test Asset",
      "asset_type" => "cash",
      "current_value" => "10000",
      "currency" => "USD"
    }

    attrs = Map.merge(default_attrs, asset_attrs)
    fill_form(attrs)
    submit_form()
  end

  def create_debt_obligation_via_ui(debt_attrs \\ %{}) do
    navigate_to("/debt_obligations")
    click({:css, "a[href='/debt_obligations/new']"})

    default_attrs = %{
      "debt_obligation_name" => "Test Debt",
      "debt_type" => "credit_card",
      "outstanding_balance" => "5000",
      "interest_rate" => "15.5",
      "minimum_payment" => "150"
    }

    attrs = Map.merge(default_attrs, debt_attrs)
    fill_form(attrs)
    submit_form()
  end

  def create_cash_flow_via_ui(cash_flow_attrs \\ %{}) do
    navigate_to("/cash_flows")
    click({:css, "a[href='/cash_flows/new']"})

    default_attrs = %{
      "cash_flow_name" => "Test Income",
      "cash_flow_type" => "income",
      "amount" => "3000",
      "frequency" => "monthly"
    }

    attrs = Map.merge(default_attrs, cash_flow_attrs)
    fill_form(attrs)
    submit_form()
  end

  # Assertion helpers
  def assert_current_path(expected_path) do
    current_url = current_url()
    assert String.contains?(current_url, expected_path)
  end

  def assert_text_present(text) do
    assert page_source() =~ text
  end

  def assert_text_not_present(text) do
    refute page_source() =~ text
  end

  def assert_element_present(selector) do
    assert element_displayed?(selector)
  end

  def assert_element_not_present(selector) do
    refute element_displayed?(selector)
  end

  # Data helpers
  def get_user_by_email(email) do
    SoupAndNutz.Accounts.get_user_by_email(email)
  end

  def get_assets_for_user(user_id) do
    SoupAndNutz.FinancialInstruments.list_assets(user_id)
  end

  def get_debt_obligations_for_user(user_id) do
    SoupAndNutz.FinancialInstruments.list_debt_obligations(user_id)
  end

  def get_cash_flows_for_user(user_id) do
    SoupAndNutz.FinancialInstruments.list_cash_flows(user_id)
  end
end
