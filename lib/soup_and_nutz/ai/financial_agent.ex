defmodule SoupAndNutz.AI.FinancialAgent do
  @moduledoc """
  Specialized financial AI agent with domain expertise in personal finance,
  investment planning, debt management, and goal setting using advanced LangChain patterns.
  """

  require Logger
  alias SoupAndNutz.AI.PromptEngine
  alias SoupAndNutz.AI.OllamaProvider

  @agent_types [
    :investment_advisor,
    :debt_strategist,
    :budget_planner,
    :retirement_planner,
    :tax_optimizer,
    :risk_assessor,
    :goal_tracker
  ]

  @doc """
  Create a specialized financial analysis chain for specific financial tasks.
  """
  def create_specialized_chain(analysis_type, user_data, model) do
    agent_config = get_agent_config(analysis_type)
    chain = build_chain(agent_config, user_data, model)
    {:ok, chain}
  end

  @doc """
  Execute a comprehensive financial analysis using multiple specialized agents.
  """
  def comprehensive_analysis(user_data, model, options \\ []) do
    analysis_types = Keyword.get(options, :include, [:investment_advisor, :debt_strategist, :budget_planner])
    
    results = 
      analysis_types
      |> Enum.map(fn type ->
        Task.async(fn ->
          case create_specialized_chain(type, user_data, model) do
            {:ok, chain} -> execute_chain(chain)
            {:error, reason} -> {:error, {type, reason}}
          end
        end)
      end)
      |> Task.await_many(60_000)
    
    case Enum.split_with(results, &match?({:ok, _}, &1)) do
      {successes, []} ->
        analysis_results = Enum.map(successes, fn {:ok, result} -> result end)
        synthesized_result = synthesize_analysis_results(analysis_results)
        {:ok, synthesized_result}
      {successes, errors} ->
        Logger.warning("Some analyses failed: #{inspect(errors)}")
        analysis_results = Enum.map(successes, fn {:ok, result} -> result end)
        partial_result = synthesize_analysis_results(analysis_results)
        {:partial, partial_result}
    end
  end

  @doc """
  Provide personalized financial recommendations based on user profile.
  """
  def personalized_recommendations(user_data, model, focus_areas \\ []) do
    user_profile = analyze_user_profile(user_data)
    
    recommendations = 
      case focus_areas do
        [] -> generate_general_recommendations(user_profile, model)
        areas -> generate_focused_recommendations(user_profile, areas, model)
      end
    
    format_recommendations(recommendations, user_profile)
  end

  @doc """
  Create a financial goal achievement plan with milestones and tracking.
  """
  def create_goal_plan(goal_data, user_financial_data, model) do
    plan_context = %{
      goal: goal_data,
      financial_situation: user_financial_data,
      risk_tolerance: assess_risk_tolerance(user_financial_data),
      time_horizon: calculate_time_horizon(goal_data)
    }
    
    case execute_goal_planning_chain(plan_context, model) do
      {:ok, raw_plan} ->
        structured_plan = structure_goal_plan(raw_plan, plan_context)
        {:ok, structured_plan}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Analyze financial risk and provide risk management recommendations.
  """
  def risk_analysis(user_data, model, analysis_depth \\ :comprehensive) do
    risk_factors = identify_risk_factors(user_data)
    risk_metrics = calculate_risk_metrics(user_data)
    
    analysis_prompt = build_risk_analysis_prompt(risk_factors, risk_metrics, analysis_depth)
    
    case OllamaProvider.generate(model, analysis_prompt) do
      {:ok, response} ->
        formatted_analysis = format_risk_analysis(response, risk_factors, risk_metrics)
        {:ok, formatted_analysis}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Generate scenario analysis for different financial situations.
  """
  def scenario_analysis(base_scenario, scenarios, model) do
    scenario_results = 
      scenarios
      |> Enum.map(fn scenario ->
        Task.async(fn ->
          analyze_scenario(base_scenario, scenario, model)
        end)
      end)
      |> Task.await_many(45_000)
    
    comparison = compare_scenarios(scenario_results)
    recommendations = generate_scenario_recommendations(comparison, model)
    
    {:ok, %{
      base_scenario: base_scenario,
      scenarios: scenario_results,
      comparison: comparison,
      recommendations: recommendations
    }}
  end

  # Private Functions

  defp get_agent_config(:investment_advisor) do
    %{
      type: :investment_advisor,
      expertise: ["portfolio management", "asset allocation", "risk assessment", "market analysis"],
      prompt_strategy: :analytical,
      specialization: :investment_planning,
      context_requirements: [:assets, :risk_tolerance, :investment_goals, :time_horizon]
    }
  end

  defp get_agent_config(:debt_strategist) do
    %{
      type: :debt_strategist,
      expertise: ["debt consolidation", "payoff strategies", "interest optimization", "credit improvement"],
      prompt_strategy: :precise,
      specialization: :debt_management,
      context_requirements: [:debts, :cash_flow, :credit_score, :payment_capacity]
    }
  end

  defp get_agent_config(:budget_planner) do
    %{
      type: :budget_planner,
      expertise: ["expense tracking", "budget optimization", "savings strategies", "cash flow management"],
      prompt_strategy: :conversational,
      specialization: :budgeting,
      context_requirements: [:income, :expenses, :savings_goals, :spending_patterns]
    }
  end

  defp get_agent_config(:retirement_planner) do
    %{
      type: :retirement_planner,
      expertise: ["retirement planning", "401k optimization", "Social Security planning", "withdrawal strategies"],
      prompt_strategy: :analytical,
      specialization: :retirement_planning,
      context_requirements: [:age, :current_savings, :retirement_goals, :expected_expenses]
    }
  end

  defp get_agent_config(:tax_optimizer) do
    %{
      type: :tax_optimizer,
      expertise: ["tax planning", "deduction strategies", "tax-advantaged accounts", "capital gains planning"],
      prompt_strategy: :precise,
      specialization: :tax_optimization,
      context_requirements: [:income, :deductions, :investments, :tax_situation]
    }
  end

  defp get_agent_config(:risk_assessor) do
    %{
      type: :risk_assessor,
      expertise: ["risk assessment", "insurance needs", "emergency planning", "portfolio risk"],
      prompt_strategy: :analytical,
      specialization: :risk_management,
      context_requirements: [:assets, :liabilities, :insurance, :emergency_fund]
    }
  end

  defp get_agent_config(:goal_tracker) do
    %{
      type: :goal_tracker,
      expertise: ["goal setting", "progress tracking", "milestone planning", "motivation strategies"],
      prompt_strategy: :conversational,
      specialization: :goal_management,
      context_requirements: [:goals, :progress, :timeline, :priorities]
    }
  end

  defp build_chain(agent_config, user_data, model) do
    %{
      agent_config: agent_config,
      user_data: filter_user_data(user_data, agent_config.context_requirements),
      model: model,
      prompt_template: get_specialized_prompt_template(agent_config.type),
      execution_strategy: get_execution_strategy(agent_config.specialization)
    }
  end

  defp execute_chain(chain) do
    context = prepare_chain_context(chain)
    prompt = generate_specialized_prompt(chain, context)
    
    case OllamaProvider.generate(chain.model, prompt, %{temperature: 0.3}) do
      {:ok, response} ->
        formatted_response = format_chain_response(response, chain.agent_config.type)
        {:ok, formatted_response}
      {:error, reason} ->
        Logger.error("Chain execution failed for #{chain.agent_config.type}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp filter_user_data(user_data, requirements) do
    requirements
    |> Enum.reduce(%{}, fn req, acc ->
      case Map.get(user_data, req) do
        nil -> acc
        value -> Map.put(acc, req, value)
      end
    end)
  end

  defp get_specialized_prompt_template(:investment_advisor) do
    """
    You are an expert investment advisor with deep knowledge of portfolio management and market analysis.
    
    User's Investment Profile:
    {{user_data}}
    
    Please provide a comprehensive investment analysis including:
    1. **Current Portfolio Assessment**
    2. **Asset Allocation Recommendations** 
    3. **Risk Analysis**
    4. **Diversification Opportunities**
    5. **Specific Investment Suggestions**
    6. **Timeline and Milestones**
    
    Base your recommendations on modern portfolio theory, the user's risk tolerance, and their investment timeline.
    """
  end

  defp get_specialized_prompt_template(:debt_strategist) do
    """
    You are a debt management specialist focused on optimizing debt payoff strategies.
    
    User's Debt Profile:
    {{user_data}}
    
    Please provide a detailed debt management plan including:
    1. **Debt Analysis and Prioritization**
    2. **Payoff Strategy (Avalanche vs Snowball)**
    3. **Consolidation Opportunities**
    4. **Interest Rate Optimization**
    5. **Payment Schedule and Timeline**
    6. **Credit Score Impact Assessment**
    
    Show specific calculations and provide a month-by-month payoff plan.
    """
  end

  defp get_specialized_prompt_template(:budget_planner) do
    """
    You are a budget planning expert specializing in expense optimization and savings strategies.
    
    User's Financial Situation:
    {{user_data}}
    
    Please create a comprehensive budget plan including:
    1. **Current Spending Analysis**
    2. **Budget Category Optimization**
    3. **Savings Opportunities**
    4. **Emergency Fund Planning**
    5. **Expense Reduction Strategies**
    6. **Budget Implementation Timeline**
    
    Provide specific dollar amounts and percentage allocations for each category.
    """
  end

  defp get_specialized_prompt_template(type) do
    """
    You are a financial expert specializing in #{type}.
    
    User's Financial Data:
    {{user_data}}
    
    Please provide detailed analysis and recommendations based on your expertise.
    Include specific, actionable advice with clear implementation steps.
    """
  end

  defp get_execution_strategy(:investment_planning) do
    %{
      analysis_depth: :comprehensive,
      calculation_focus: :portfolio_metrics,
      recommendation_style: :strategic,
      risk_consideration: :primary
    }
  end

  defp get_execution_strategy(:debt_management) do
    %{
      analysis_depth: :detailed,
      calculation_focus: :payoff_optimization,
      recommendation_style: :actionable,
      risk_consideration: :moderate
    }
  end

  defp get_execution_strategy(_) do
    %{
      analysis_depth: :standard,
      calculation_focus: :general,
      recommendation_style: :balanced,
      risk_consideration: :moderate
    }
  end

  defp prepare_chain_context(chain) do
    %{
      user_data: format_user_data_for_prompt(chain.user_data),
      agent_type: chain.agent_config.type,
      expertise_areas: chain.agent_config.expertise,
      analysis_timestamp: DateTime.utc_now()
    }
  end

  defp generate_specialized_prompt(chain, context) do
    chain.prompt_template
    |> String.replace("{{user_data}}", context.user_data)
    |> add_expertise_context(chain.agent_config.expertise)
    |> add_calculation_requirements(chain.execution_strategy)
  end

  defp format_user_data_for_prompt(user_data) do
    user_data
    |> Enum.map(fn {key, value} ->
      "#{format_key(key)}: #{format_value(value)}"
    end)
    |> Enum.join("\n")
  end

  defp format_key(key), do: key |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp format_value(value) when is_list(value) do
    case value do
      [] -> "None"
      items -> 
        items
        |> Enum.take(5)  # Limit to first 5 items
        |> Enum.map(&format_single_value/1)
        |> Enum.join(", ")
    end
  end
  defp format_value(value), do: format_single_value(value)

  defp format_single_value(%Money{} = money), do: Money.to_string(money)
  defp format_single_value(value) when is_map(value) do
    case Map.get(value, :name) || Map.get(value, :description) do
      nil -> inspect(value)
      name -> name
    end
  end
  defp format_single_value(value), do: to_string(value)

  defp add_expertise_context(prompt, expertise) do
    expertise_text = """
    
    Your areas of expertise include: #{Enum.join(expertise, ", ")}.
    Draw upon this specialized knowledge to provide expert-level advice.
    """
    
    prompt <> expertise_text
  end

  defp add_calculation_requirements(prompt, strategy) do
    case strategy.calculation_focus do
      :portfolio_metrics ->
        prompt <> "\n\nInclude specific portfolio metrics, risk calculations, and return projections."
      :payoff_optimization ->
        prompt <> "\n\nShow detailed payoff calculations, interest savings, and timeline projections."
      _ ->
        prompt <> "\n\nInclude relevant financial calculations where applicable."
    end
  end

  defp format_chain_response(response, agent_type) do
    %{
      agent_type: agent_type,
      analysis: response.text,
      confidence_score: calculate_confidence_score(response),
      key_recommendations: extract_key_recommendations(response.text),
      action_items: extract_action_items(response.text),
      metadata: %{
        model_used: response.model,
        processing_time: response.metadata[:total_duration],
        token_usage: response.usage,
        timestamp: DateTime.utc_now()
      }
    }
  end

  defp synthesize_analysis_results(results) do
    %{
      overall_assessment: synthesize_assessments(results),
      priority_recommendations: prioritize_recommendations(results),
      integrated_action_plan: create_integrated_plan(results),
      confidence_metrics: aggregate_confidence_metrics(results),
      next_steps: generate_next_steps(results)
    }
  end

  defp analyze_user_profile(user_data) do
    %{
      financial_health_score: calculate_financial_health(user_data),
      risk_tolerance: assess_risk_tolerance(user_data),
      life_stage: determine_life_stage(user_data),
      primary_concerns: identify_primary_concerns(user_data),
      strengths: identify_strengths(user_data),
      improvement_areas: identify_improvement_areas(user_data)
    }
  end

  defp assess_risk_tolerance(user_data) do
    # Simplified risk assessment based on available data
    age = Map.get(user_data, :age, 35)
    assets = Map.get(user_data, :assets, [])
    debts = Map.get(user_data, :debts, [])
    
    cond do
      age < 30 and length(debts) <= 2 -> :aggressive
      age < 45 and length(assets) > length(debts) -> :moderate
      age > 50 or length(debts) > length(assets) -> :conservative
      true -> :moderate
    end
  end

  defp calculate_time_horizon(goal_data) do
    target_date = Map.get(goal_data, :target_date)
    
    case target_date do
      nil -> :medium_term
      date ->
        months = DateTime.diff(date, DateTime.utc_now(), :day) / 30
        cond do
          months < 12 -> :short_term
          months < 60 -> :medium_term
          true -> :long_term
        end
    end
  end

  defp execute_goal_planning_chain(plan_context, model) do
    prompt = """
    Create a detailed financial plan to achieve the following goal:
    
    Goal: #{format_goal(plan_context.goal)}
    Current Financial Situation: #{format_financial_situation(plan_context.financial_situation)}
    Risk Tolerance: #{plan_context.risk_tolerance}
    Time Horizon: #{plan_context.time_horizon}
    
    Provide a comprehensive plan with:
    1. Feasibility assessment
    2. Required monthly savings/investment
    3. Recommended investment strategy
    4. Key milestones and timeline
    5. Risk mitigation strategies
    6. Progress tracking recommendations
    """
    
    OllamaProvider.generate(model, prompt, %{temperature: 0.2})
  end

  defp identify_risk_factors(user_data) do
    factors = []
    
    factors = if Map.get(user_data, :emergency_fund, Money.new(0)) |> Money.to_string() == "$0.00" do
      ["No emergency fund" | factors]
    else
      factors
    end
    
    factors = if length(Map.get(user_data, :debts, [])) > 3 do
      ["High debt load" | factors]
    else
      factors
    end
    
    factors = if length(Map.get(user_data, :assets, [])) < 2 do
      ["Limited asset diversification" | factors]
    else
      factors
    end
    
    factors
  end

  defp calculate_risk_metrics(user_data) do
    assets = Map.get(user_data, :assets, [])
    debts = Map.get(user_data, :debts, [])
    
    total_assets = calculate_total_value(assets, :current_value)
    total_debts = calculate_total_value(debts, :outstanding_balance)
    
    %{
      debt_to_asset_ratio: calculate_ratio(total_debts, total_assets),
      asset_count: length(assets),
      debt_count: length(debts),
      net_worth: Money.subtract(total_assets, total_debts)
    }
  end

  defp calculate_total_value(items, field) do
    items
    |> Enum.map(&Map.get(&1, field, Money.new(0)))
    |> Enum.reduce(Money.new(0), &Money.add/2)
  end

  defp calculate_ratio(numerator, denominator) do
    if Money.positive?(denominator) do
      Money.to_decimal(numerator) / Money.to_decimal(denominator)
    else
      0.0
    end
  end

  # Placeholder implementations for complex functions
  defp calculate_confidence_score(_response), do: 0.85
  defp extract_key_recommendations(text), do: [String.slice(text, 0..100) <> "..."]
  defp extract_action_items(text), do: [String.slice(text, 0..50) <> "..."]
  defp synthesize_assessments(_results), do: "Overall financial health is good with areas for improvement"
  defp prioritize_recommendations(_results), do: ["Focus on debt reduction", "Increase emergency fund"]
  defp create_integrated_plan(_results), do: "Integrated 6-month financial improvement plan"
  defp aggregate_confidence_metrics(_results), do: %{average_confidence: 0.85}
  defp generate_next_steps(_results), do: ["Review budget", "Set up automatic savings"]
  defp calculate_financial_health(_user_data), do: 75
  defp determine_life_stage(_user_data), do: :accumulation
  defp identify_primary_concerns(_user_data), do: ["debt", "savings"]
  defp identify_strengths(_user_data), do: ["steady_income"]
  defp identify_improvement_areas(_user_data), do: ["emergency_fund", "investment_diversification"]
  defp generate_general_recommendations(_profile, _model), do: []
  defp generate_focused_recommendations(_profile, _areas, _model), do: []
  defp format_recommendations(recommendations, _profile), do: recommendations
  defp structure_goal_plan(raw_plan, _context), do: raw_plan
  defp build_risk_analysis_prompt(_factors, _metrics, _depth), do: "Analyze financial risk..."
  defp format_risk_analysis(response, _factors, _metrics), do: response
  defp analyze_scenario(_base, _scenario, _model), do: {:ok, "scenario_result"}
  defp compare_scenarios(_results), do: %{best: "scenario_1"}
  defp generate_scenario_recommendations(_comparison, _model), do: ["recommendation"]
  defp format_goal(_goal), do: "Goal details"
  defp format_financial_situation(_situation), do: "Financial situation summary"
end