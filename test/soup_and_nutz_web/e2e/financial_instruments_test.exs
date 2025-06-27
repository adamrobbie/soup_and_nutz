defmodule SoupAndNutzWeb.E2E.FinancialInstrumentsTest do
  @moduledoc """
  End-to-end tests for financial instruments management.
  """

  use SoupAndNutzWeb.E2ECase, async: false

  describe "asset management" do
    test "user can create a new asset" do
      user = sign_in_user()

      navigate_to("/assets")
      click({:css, "a[href='/assets/new']"})

      fill_form(%{
        "asset_name" => "Test Savings Account",
        "asset_type" => "cash",
        "current_value" => "25000",
        "currency" => "USD"
      })

      submit_form()

      # Should redirect to assets index
      assert_current_path("/assets")
      assert_text_present("Test Savings Account")
      assert_text_present("$25,000.00")
    end

    test "user can view asset details" do
      user = sign_in_user()
      asset = insert(:asset, user: user, asset_name: "Test Asset")

      navigate_to("/assets")
      click({:css, "a[href='/assets/#{asset.id}']"})

      assert_current_path("/assets/#{asset.id}")
      assert_text_present("Test Asset")
    end

    test "user can edit an asset" do
      user = sign_in_user()
      asset = insert(:asset, user: user, asset_name: "Original Name")

      navigate_to("/assets/#{asset.id}/edit")

      fill_form(%{
        "asset_name" => "Updated Asset Name",
        "current_value" => "50000"
      })

      submit_form()

      assert_current_path("/assets/#{asset.id}")
      assert_text_present("Updated Asset Name")
      assert_text_present("$50,000.00")
    end

    test "user can delete an asset" do
      user = sign_in_user()
      asset = insert(:asset, user: user, asset_name: "Asset to Delete")

      navigate_to("/assets")
      assert_text_present("Asset to Delete")

      # Delete the asset
      click({:css, "button[data-confirm='Are you sure?']"})

      # Should redirect to assets index
      assert_current_path("/assets")
      assert_text_not_present("Asset to Delete")
    end

    test "user cannot see other users assets" do
      user1 = sign_in_user()
      user2 = insert(:user)
      asset = insert(:asset, user: user2, asset_name: "Other User Asset")

      navigate_to("/assets")

      # Should not see other user's asset
      assert_text_not_present("Other User Asset")
    end
  end

  describe "debt obligation management" do
    test "user can create a new debt obligation" do
      user = sign_in_user()

      navigate_to("/debt_obligations")
      click({:css, "a[href='/debt_obligations/new']"})

      fill_form(%{
        "debt_obligation_name" => "Test Credit Card",
        "debt_type" => "credit_card",
        "outstanding_balance" => "5000",
        "interest_rate" => "18.5",
        "minimum_payment" => "150"
      })

      submit_form()

      assert_current_path("/debt_obligations")
      assert_text_present("Test Credit Card")
      assert_text_present("$5,000.00")
    end

    test "user can view debt obligation details" do
      user = sign_in_user()
      debt = insert(:debt_obligation, user: user, debt_obligation_name: "Test Debt")

      navigate_to("/debt_obligations")
      click({:css, "a[href='/debt_obligations/#{debt.id}']"})

      assert_current_path("/debt_obligations/#{debt.id}")
      assert_text_present("Test Debt")
    end

    test "user can edit a debt obligation" do
      user = sign_in_user()
      debt = insert(:debt_obligation, user: user, debt_obligation_name: "Original Debt")

      navigate_to("/debt_obligations/#{debt.id}/edit")

      fill_form(%{
        "debt_obligation_name" => "Updated Debt Name",
        "outstanding_balance" => "3000"
      })

      submit_form()

      assert_current_path("/debt_obligations/#{debt.id}")
      assert_text_present("Updated Debt Name")
      assert_text_present("$3,000.00")
    end

    test "user can delete a debt obligation" do
      user = sign_in_user()
      debt = insert(:debt_obligation, user: user, debt_obligation_name: "Debt to Delete")

      navigate_to("/debt_obligations")
      assert_text_present("Debt to Delete")

      click({:css, "button[data-confirm='Are you sure?']"})

      assert_current_path("/debt_obligations")
      assert_text_not_present("Debt to Delete")
    end
  end

  describe "cash flow management" do
    test "user can create a new cash flow" do
      user = sign_in_user()

      navigate_to("/cash_flows")
      click({:css, "a[href='/cash_flows/new']"})

      fill_form(%{
        "cash_flow_name" => "Monthly Salary",
        "cash_flow_type" => "income",
        "amount" => "5000",
        "frequency" => "monthly"
      })

      submit_form()

      assert_current_path("/cash_flows")
      assert_text_present("Monthly Salary")
      assert_text_present("$5,000.00")
    end

    test "user can view cash flow details" do
      user = sign_in_user()
      cash_flow = insert(:cash_flow, user: user, cash_flow_name: "Test Cash Flow")

      navigate_to("/cash_flows")
      click({:css, "a[href='/cash_flows/#{cash_flow.id}']"})

      assert_current_path("/cash_flows/#{cash_flow.id}")
      assert_text_present("Test Cash Flow")
    end

    test "user can edit a cash flow" do
      user = sign_in_user()
      cash_flow = insert(:cash_flow, user: user, cash_flow_name: "Original Cash Flow")

      navigate_to("/cash_flows/#{cash_flow.id}/edit")

      fill_form(%{
        "cash_flow_name" => "Updated Cash Flow Name",
        "amount" => "6000"
      })

      submit_form()

      assert_current_path("/cash_flows/#{cash_flow.id}")
      assert_text_present("Updated Cash Flow Name")
      assert_text_present("$6,000.00")
    end

    test "user can delete a cash flow" do
      user = sign_in_user()
      cash_flow = insert(:cash_flow, user: user, cash_flow_name: "Cash Flow to Delete")

      navigate_to("/cash_flows")
      assert_text_present("Cash Flow to Delete")

      click({:css, "button[data-confirm='Are you sure?']"})

      assert_current_path("/cash_flows")
      assert_text_not_present("Cash Flow to Delete")
    end
  end

  describe "data isolation" do
    test "users can only see their own financial data" do
      user1 = sign_in_user()
      user2 = insert(:user)

      # Create data for both users
      asset1 = insert(:asset, user: user1, asset_name: "User1 Asset")
      asset2 = insert(:asset, user: user2, asset_name: "User2 Asset")
      debt1 = insert(:debt_obligation, user: user1, debt_obligation_name: "User1 Debt")
      debt2 = insert(:debt_obligation, user: user2, debt_obligation_name: "User2 Debt")

      # Check assets
      navigate_to("/assets")
      assert_text_present("User1 Asset")
      assert_text_not_present("User2 Asset")

      # Check debt obligations
      navigate_to("/debt_obligations")
      assert_text_present("User1 Debt")
      assert_text_not_present("User2 Debt")
    end
  end
end
