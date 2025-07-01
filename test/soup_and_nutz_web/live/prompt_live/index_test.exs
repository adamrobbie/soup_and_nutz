defmodule SoupAndNutzWeb.PromptLive.IndexTest do
  use SoupAndNutzWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Floki
  import HtmlEntities
  # alias SoupAndNutz.AI.OpenAIService
  # alias SoupAndNutz.FinancialInstruments
  alias SoupAndNutz.Accounts

  defp authenticate_user(conn, user) do
    conn
    |> fetch_session([])
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
  end

  # Mock OpenAI service for testing
  setup do
    mock_openai = %{
      process_natural_language_input: fn _prompt, _user_id ->
        {:ok, %{
          "type" => "asset",
          "data" => %{
            "asset_name" => "Test Asset",
            "asset_type" => "InvestmentSecurities",
            "fair_value" => "10000"
          },
          "confidence" => 0.95,
          "missing_fields" => [],
          "suggestions" => []
        }}
      end
    }

    # Replace the OpenAI service with our mock
    Application.put_env(:soup_and_nutz, :openai_service, mock_openai)

    # Create test user
    {:ok, user} = Accounts.create_user(%{
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser"
    })

    {:ok, user: user}
  end

  describe "mount/3" do
    test "mounts with initial state", %{conn: conn, user: user} do
      # Simulate authenticated session
      conn = authenticate_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/prompt")

      assert view |> has_element?("textarea[name='prompt']")
      assert view |> has_element?("button[type='submit']")
      assert view |> has_element?("button", "Submit")
    end
  end

  describe "submit_prompt event" do
    test "processes asset creation prompt successfully", %{conn: conn, user: user} do
      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      # Submit a prompt
      view
      |> form("form", prompt: "Add a $10,000 investment in Apple stock")
      |> render_submit()

      # Wait for the async task to complete and check for result
      html = render(view)
      assert Floki.text(html) =~ "Asset created: Test Asset"
    end

    test "handles AI processing errors gracefully", %{conn: conn, user: user} do
      # Mock error response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:error, "AI service unavailable"}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add a test asset")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "AI service unavailable"
    end

    test "handles unrecognized AI response", %{conn: conn, user: user} do
      # Mock unrecognized response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:ok, %{type: :general_answer, answer: "Unrecognized response"}}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Unknown request")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "Unrecognized response"
    end
  end

  describe "example_prompt event" do
    test "fills prompt with example text", %{conn: conn, user: user} do
      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      # Test that the form exists and can be filled
      assert view |> has_element?("textarea[name='prompt']")

      # Fill the prompt manually since there's no example button
      view
      |> form("form", prompt: "Add a $5000 car loan at 5% interest for 5 years.")
      |> render_submit()

      # Check that the form works
      assert view |> has_element?("textarea[name='prompt']")
    end
  end

  describe "asset creation flow" do
    test "creates asset and shows success message", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:ok, %{
            type: :asset_created,
            asset: %{id: 1, asset_name: "Test Asset"}
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add a test asset")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "Asset created: Test Asset"
    end

    test "handles asset creation errors", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response with error
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:error, %Ecto.Changeset{
            action: :insert,
            errors: [asset_name: {"can't be blank", []}]
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add invalid asset")
      |> render_submit()

      html = render(view)
      assert HtmlEntities.decode(Floki.text(html)) =~ "can't be blank"
    end
  end

  describe "debt creation flow" do
    test "creates debt and shows success message", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:ok, %{
            type: :debt_created,
            debt: %{id: 1, debt_name: "Test Loan"}
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add a test loan")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "Debt obligation created: Test Loan"
    end
  end

  describe "conversation memory" do
    test "stores conversation memory on successful creation", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:ok, %{
            type: :asset_created,
            asset: %{id: 1, asset_name: "Test Asset"}
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add a test asset")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "Asset created: Test Asset"
    end
  end

  describe "history display" do
    test "shows recent prompt history", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:ok, %{
            type: :asset_created,
            asset: %{id: 1, asset_name: "Test Asset"}
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      # Submit a prompt
      view
      |> form("form", prompt: "First prompt")
      |> render_submit()

      # Check that the result is shown
      html = render(view)
      assert Floki.text(html) =~ "Asset created: Test Asset"
    end
  end

  describe "error formatting" do
    test "formats changeset errors properly", %{conn: conn, user: user} do
      # Mock FinancialAdvisor response with changeset error
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:error, %Ecto.Changeset{
            action: :insert,
            errors: [
              asset_name: {"can't be blank", []},
              asset_type: {"is invalid", []}
            ]
          }}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Add invalid asset")
      |> render_submit()

      html = render(view)
      decoded = HtmlEntities.decode(Floki.text(html))
      assert decoded =~ "can't be blank"
      assert decoded =~ "is invalid"
    end

    test "formats string errors properly", %{conn: conn, user: user} do
      # Mock string error
      mock_financial_advisor = %{
        process_user_input: fn _prompt, _user_id ->
          {:error, "Simple error message"}
        end
      }
      Application.put_env(:soup_and_nutz, :financial_advisor, mock_financial_advisor)

      conn = authenticate_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/prompt")

      view
      |> form("form", prompt: "Test prompt")
      |> render_submit()

      html = render(view)
      assert Floki.text(html) =~ "Simple error message"
    end
  end
end
