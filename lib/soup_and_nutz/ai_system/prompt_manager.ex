defmodule SoupAndNutz.AISystem.PromptManager do
  @moduledoc """
  Manages prompt template selection and formatting for the AI system.

  Intelligently selects the appropriate prompt template based on the user's question
  and financial context, then formats it with the relevant data.
  """

  alias SoupAndNutz.AISystem.PromptTemplates
  alias LangChain.PromptTemplate

  @doc """
  Analyzes a user's question and selects the most appropriate prompt template.
  """
  def select_prompt_template(message, context \\ %{}) do
    message_lower = String.downcase(message)

    cond do
      # Budget and spending analysis
      contains_any?(message_lower, ["budget", "spending", "expenses", "income", "save money"]) ->
        {:ok, PromptTemplates.budget_analysis_prompt(), :budget_analysis}

      # Debt management
      contains_any?(message_lower, ["debt", "loan", "credit card", "pay off", "snowball", "avalanche"]) ->
        {:ok, PromptTemplates.debt_payoff_prompt(), :debt_payoff}

      # Investment advice
      contains_any?(message_lower, ["invest", "portfolio", "stocks", "bonds", "asset allocation", "risk tolerance"]) ->
        {:ok, PromptTemplates.investment_recommendation_prompt(), :investment_recommendation}

      # Net worth analysis
      contains_any?(message_lower, ["net worth", "assets", "liabilities", "wealth"]) ->
        {:ok, PromptTemplates.net_worth_analysis_prompt(), :net_worth_analysis}

      # Goal planning
      contains_any?(message_lower, ["goal", "plan", "target", "achieve", "timeline"]) ->
        {:ok, PromptTemplates.goal_planning_prompt(), :goal_planning}

      # Cash flow
      contains_any?(message_lower, ["cash flow", "monthly", "income", "expenses", "emergency fund"]) ->
        {:ok, PromptTemplates.cash_flow_analysis_prompt(), :cash_flow_analysis}

      # Retirement planning
      contains_any?(message_lower, ["retirement", "401k", "ira", "social security", "pension"]) ->
        {:ok, PromptTemplates.retirement_planning_prompt(), :retirement_planning}

      # Financial education
      contains_any?(message_lower, ["what is", "explain", "how does", "learn about", "understand"]) ->
        {:ok, PromptTemplates.financial_education_prompt(), :financial_education}

      # General financial advice
      true ->
        {:ok, PromptTemplates.general_financial_prompt(), :general_financial}
    end
  end

  @doc """
  Formats a prompt template with user data and context.
  """
    def format_prompt(template, message, context \\ %{}) do
    # Extract financial data from context
    financial_data = extract_financial_data(context)

    # Format the prompt based on the template type
    format_prompt_by_type(template, message, financial_data, context)
  end

  @doc """
  Creates a complete prompt with template and user data.
  """
  def create_prompt(message, context \\ %{}) do
    case select_prompt_template(message, context) do
      {:ok, template, template_type} ->
        case format_prompt(template, message, context) do
          {:ok, formatted_prompt} ->
            {:ok, formatted_prompt, template_type}
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helper functions

  defp contains_any?(text, keywords) do
    Enum.any?(keywords, fn keyword -> String.contains?(text, keyword) end)
  end

  defp extract_financial_data(context) do
    %{
      income: Map.get(context, :income, "Not provided"),
      expenses: Map.get(context, :expenses, "Not provided"),
      savings: Map.get(context, :savings, "Not provided"),
      debt: Map.get(context, :debt, "Not provided"),
      assets: Map.get(context, :assets, "Not provided"),
      liabilities: Map.get(context, :liabilities, "Not provided"),
      net_worth: Map.get(context, :net_worth, "Not provided"),
      age: Map.get(context, :age, "Not provided"),
      goals: Map.get(context, :goals, "Not provided"),
      risk_tolerance: Map.get(context, :risk_tolerance, "Not provided")
    }
  end

  defp format_prompt_by_type(template, message, financial_data, context) do
    case get_template_variables(template) do
      ["financial_context", "user_question"] ->
        # General financial advisor prompt
        financial_context = build_financial_context(financial_data)
        {:ok, PromptTemplate.format(template, %{
          financial_context: financial_context,
          user_question: message
        })}

      ["income_data", "expense_data", "savings_data", "debt_data"] ->
        # Budget analysis prompt
        {:ok, PromptTemplate.format(template, %{
          income_data: financial_data.income,
          expense_data: financial_data.expenses,
          savings_data: financial_data.savings,
          debt_data: financial_data.debt
        })}

      ["debt_list", "monthly_payment", "income", "other_obligations"] ->
        # Debt payoff prompt
        {:ok, PromptTemplate.format(template, %{
          debt_list: financial_data.debt,
          monthly_payment: Map.get(context, :monthly_payment, "Not specified"),
          income: financial_data.income,
          other_obligations: Map.get(context, :other_obligations, "Not specified")
        })}

      ["age", "risk_tolerance", "timeline", "current_portfolio", "available_capital", "financial_goals"] ->
        # Investment recommendation prompt
        {:ok, PromptTemplate.format(template, %{
          age: financial_data.age,
          risk_tolerance: financial_data.risk_tolerance,
          timeline: Map.get(context, :timeline, "Not specified"),
          current_portfolio: Map.get(context, :current_portfolio, "Not specified"),
          available_capital: Map.get(context, :available_capital, "Not specified"),
          financial_goals: financial_data.goals
        })}

      ["net_worth", "assets", "liabilities", "trend", "life_stage"] ->
        # Net worth analysis prompt
        {:ok, PromptTemplate.format(template, %{
          net_worth: financial_data.net_worth,
          assets: financial_data.assets,
          liabilities: financial_data.liabilities,
          trend: Map.get(context, :trend, "Not specified"),
          life_stage: Map.get(context, :life_stage, "Not specified")
        })}

      ["goals", "current_situation", "timeline", "available_resources", "risk_tolerance"] ->
        # Goal planning prompt
        {:ok, PromptTemplate.format(template, %{
          goals: financial_data.goals,
          current_situation: build_financial_context(financial_data),
          timeline: Map.get(context, :timeline, "Not specified"),
          available_resources: Map.get(context, :available_resources, "Not specified"),
          risk_tolerance: financial_data.risk_tolerance
        })}

      ["monthly_income", "monthly_expenses", "cash_flow", "seasonal_variations", "emergency_fund"] ->
        # Cash flow analysis prompt
        {:ok, PromptTemplate.format(template, %{
          monthly_income: financial_data.income,
          monthly_expenses: financial_data.expenses,
          cash_flow: Map.get(context, :cash_flow, "Not calculated"),
          seasonal_variations: Map.get(context, :seasonal_variations, "Not specified"),
          emergency_fund: Map.get(context, :emergency_fund, "Not specified")
        })}

      ["current_age", "retirement_age", "current_savings", "retirement_expenses", "social_security", "other_income"] ->
        # Retirement planning prompt
        {:ok, PromptTemplate.format(template, %{
          current_age: financial_data.age,
          retirement_age: Map.get(context, :retirement_age, "Not specified"),
          current_savings: financial_data.savings,
          retirement_expenses: Map.get(context, :retirement_expenses, "Not specified"),
          social_security: Map.get(context, :social_security, "Not specified"),
          other_income: Map.get(context, :other_income, "Not specified")
        })}

      ["question", "context"] ->
        # General financial prompt
        financial_context = build_financial_context(financial_data)
        {:ok, PromptTemplate.format(template, %{
          question: message,
          context: financial_context
        })}

      ["topic", "knowledge_level", "question"] ->
        # Financial education prompt
        {:ok, PromptTemplate.format(template, %{
          topic: extract_topic_from_question(message),
          knowledge_level: Map.get(context, :knowledge_level, "beginner"),
          question: message
        })}

      _ ->
        # Fallback to general financial prompt
        financial_context = build_financial_context(financial_data)
        general_template = PromptTemplates.general_financial_prompt()
        {:ok, PromptTemplate.format(general_template, %{
          question: message,
          context: financial_context
        })}
    end
  end

    defp get_template_variables(template) do
    # Extract variables from the template text using regex for EEx syntax
    text = Map.get(template, :text, "")

    # Find all variables in the format <%= @variable_name %>
    case Regex.scan(~r/<%= @([^%>]+) %>/, text) do
      matches when is_list(matches) ->
        matches
        |> Enum.map(fn [_, var_name] -> var_name end)
        |> Enum.uniq()

      _ ->
        []
    end
  end

  defp build_financial_context(financial_data) do
    context_parts = []

    context_parts = if financial_data.income != "Not provided" do
      ["Income: #{financial_data.income}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.expenses != "Not provided" do
      ["Expenses: #{financial_data.expenses}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.savings != "Not provided" do
      ["Savings: #{financial_data.savings}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.debt != "Not provided" do
      ["Debt: #{financial_data.debt}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.net_worth != "Not provided" do
      ["Net Worth: #{financial_data.net_worth}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.age != "Not provided" do
      ["Age: #{financial_data.age}" | context_parts]
    else
      context_parts
    end

    context_parts = if financial_data.goals != "Not provided" do
      ["Financial Goals: #{financial_data.goals}" | context_parts]
    else
      context_parts
    end

    if Enum.empty?(context_parts) do
      "Limited financial information available"
    else
      Enum.join(context_parts, "; ")
    end
  end

  defp extract_topic_from_question(question) do
    question_lower = String.downcase(question)

    cond do
      String.contains?(question_lower, "what is") ->
        # Extract the topic after "what is"
        case Regex.run(~r/what is (.+?)(?:\?|$)/i, question) do
          [_, topic] -> String.trim(topic)
          _ -> "financial concept"
        end

      String.contains?(question_lower, "explain") ->
        # Extract the topic after "explain"
        case Regex.run(~r/explain (.+?)(?:\?|$)/i, question) do
          [_, topic] -> String.trim(topic)
          _ -> "financial concept"
        end

      String.contains?(question_lower, "how does") ->
        # Extract the topic after "how does"
        case Regex.run(~r/how does (.+?)(?:\?|$)/i, question) do
          [_, topic] -> String.trim(topic)
          _ -> "financial concept"
        end

      true ->
        "financial concept"
    end
  end
end
