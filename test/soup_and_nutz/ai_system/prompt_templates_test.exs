defmodule SoupAndNutz.AISystem.PromptTemplatesTest do
  use ExUnit.Case, async: true

  alias SoupAndNutz.AISystem.PromptTemplates
  alias SoupAndNutz.AISystem.PromptManager

  @moduletag :unit

  describe "prompt templates" do
        test "financial_advisor_prompt creates valid template" do
      template = PromptTemplates.financial_advisor_prompt()

      assert template.text =~ "You are a professional financial advisor"
      assert template.text =~ "<%= @financial_context %>"
      assert template.text =~ "<%= @user_question %>"
    end

        test "budget_analysis_prompt creates valid template" do
      template = PromptTemplates.budget_analysis_prompt()

      assert template.text =~ "budget analysis expert"
      assert template.text =~ "<%= @income_data %>"
      assert template.text =~ "<%= @expense_data %>"
      assert template.text =~ "<%= @savings_data %>"
      assert template.text =~ "<%= @debt_data %>"
    end

    test "debt_payoff_prompt creates valid template" do
      template = PromptTemplates.debt_payoff_prompt()

      assert template.text =~ "debt management specialist"
      assert template.text =~ "<%= @debt_list %>"
      assert template.text =~ "<%= @monthly_payment %>"
      assert template.text =~ "<%= @income %>"
    end

    test "investment_recommendation_prompt creates valid template" do
      template = PromptTemplates.investment_recommendation_prompt()

      assert template.text =~ "investment advisor"
      assert template.text =~ "<%= @age %>"
      assert template.text =~ "<%= @risk_tolerance %>"
      assert template.text =~ "<%= @timeline %>"
    end

    test "net_worth_analysis_prompt creates valid template" do
      template = PromptTemplates.net_worth_analysis_prompt()

      assert template.text =~ "net worth analysis expert"
      assert template.text =~ "<%= @net_worth %>"
      assert template.text =~ "<%= @assets %>"
      assert template.text =~ "<%= @liabilities %>"
    end

    test "goal_planning_prompt creates valid template" do
      template = PromptTemplates.goal_planning_prompt()

      assert template.text =~ "financial goal planning specialist"
      assert template.text =~ "<%= @goals %>"
      assert template.text =~ "<%= @current_situation %>"
      assert template.text =~ "<%= @timeline %>"
    end

    test "cash_flow_analysis_prompt creates valid template" do
      template = PromptTemplates.cash_flow_analysis_prompt()

      assert template.text =~ "cash flow analysis expert"
      assert template.text =~ "<%= @monthly_income %>"
      assert template.text =~ "<%= @monthly_expenses %>"
      assert template.text =~ "<%= @cash_flow %>"
    end

    test "retirement_planning_prompt creates valid template" do
      template = PromptTemplates.retirement_planning_prompt()

      assert template.text =~ "retirement planning specialist"
      assert template.text =~ "<%= @current_age %>"
      assert template.text =~ "<%= @retirement_age %>"
      assert template.text =~ "<%= @current_savings %>"
    end

    test "general_financial_prompt creates valid template" do
      template = PromptTemplates.general_financial_prompt()

      assert template.text =~ "knowledgeable financial advisor"
      assert template.text =~ "<%= @question %>"
      assert template.text =~ "<%= @context %>"
    end

    test "financial_education_prompt creates valid template" do
      template = PromptTemplates.financial_education_prompt()

      assert template.text =~ "financial educator"
      assert template.text =~ "<%= @topic %>"
      assert template.text =~ "<%= @knowledge_level %>"
      assert template.text =~ "<%= @question %>"
    end
  end

  describe "prompt manager" do
    test "select_prompt_template selects budget template for budget questions" do
      message = "How can I improve my budget?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :budget_analysis
      assert template.text =~ "budget analysis expert"
    end

    test "select_prompt_template selects debt template for debt questions" do
      message = "What's the best way to pay off my credit card debt?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :debt_payoff
      assert template.text =~ "debt management specialist"
    end

    test "select_prompt_template selects investment template for investment questions" do
      message = "What should I invest in for retirement?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :investment_recommendation
      assert template.text =~ "investment advisor"
    end

    test "select_prompt_template selects net worth template for net worth questions" do
      message = "How is my net worth looking?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :net_worth_analysis
      assert template.text =~ "net worth analysis expert"
    end

    test "select_prompt_template selects goal planning template for goal questions" do
      message = "How can I achieve my financial goals?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :goal_planning
      assert template.text =~ "financial goal planning specialist"
    end

    test "select_prompt_template selects cash flow template for cash flow questions" do
      message = "How can I improve my monthly cash flow?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :cash_flow_analysis
      assert template.text =~ "cash flow analysis expert"
    end

    test "select_prompt_template selects retirement template for retirement questions" do
      message = "How much should I save for retirement?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :retirement_planning
      assert template.text =~ "retirement planning specialist"
    end

    test "select_prompt_template selects education template for learning questions" do
      message = "What is compound interest?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :financial_education
      assert template.text =~ "financial educator"
    end

    test "select_prompt_template falls back to general template for unknown questions" do
      message = "Hello, how are you?"
      {:ok, template, template_type} = PromptManager.select_prompt_template(message)

      assert template_type == :general_financial
      assert template.text =~ "knowledgeable financial advisor"
    end

        test "create_prompt formats template with context" do
      message = "How can I improve my budget?"
      context = %{
        income: "$5,000/month",
        expenses: "$4,200/month",
        savings: "$500/month",
        debt: "$15,000 credit card"
      }

      {:ok, formatted_prompt, template_type} = PromptManager.create_prompt(message, context)

      assert template_type == :budget_analysis
      assert formatted_prompt =~ "budget analysis expert"
      assert formatted_prompt =~ "Income: $5,000/month"
      assert formatted_prompt =~ "Expenses: $4,200/month"
      assert formatted_prompt =~ "Savings: $500/month"
      assert formatted_prompt =~ "Debt: $15,000 credit card"
    end

        test "create_prompt handles missing context gracefully" do
      message = "What should I invest in?"

      {:ok, formatted_prompt, template_type} = PromptManager.create_prompt(message, %{})

      assert template_type == :investment_recommendation
      assert formatted_prompt =~ "investment advisor"
      assert formatted_prompt =~ "Not provided"
      assert formatted_prompt =~ "Not specified"
    end

        test "extract_topic_from_question works correctly" do
      # This tests the private function indirectly through create_prompt
      message = "What is compound interest?"
      context = %{knowledge_level: "beginner"}

      {:ok, formatted_prompt, template_type} = PromptManager.create_prompt(message, context)

      assert template_type == :financial_education
      assert formatted_prompt =~ "financial educator"
      assert formatted_prompt =~ "compound interest"
    end
  end
end
