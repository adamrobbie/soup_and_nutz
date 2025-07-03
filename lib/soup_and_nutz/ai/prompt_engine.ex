defmodule SoupAndNutz.AI.PromptEngine do
  @moduledoc """
  Advanced prompt engineering system with sophisticated templating,
  chain-of-thought reasoning, few-shot learning, and financial domain expertise.
  """

  defstruct [
    :templates,
    :financial_personas,
    :prompt_strategies,
    :few_shot_examples
  ]

  @doc """
  Create a new prompt engine with predefined templates and strategies.
  """
  def new() do
    %__MODULE__{
      templates: load_prompt_templates(),
      financial_personas: load_financial_personas(),
      prompt_strategies: load_prompt_strategies(),
      few_shot_examples: load_few_shot_examples()
    }
  end

  @doc """
  Generate a sophisticated prompt based on strategy and context.
  """
  def generate_prompt(engine, strategy, context) do
    base_prompt = build_base_prompt(engine, strategy, context)
    enhanced_prompt = enhance_with_context(base_prompt, context)
    finalized_prompt = apply_prompt_techniques(enhanced_prompt, strategy, engine)
    
    finalized_prompt
  end

  @doc """
  Create a chain-of-thought prompt for complex financial reasoning.
  """
  def create_cot_prompt(engine, problem, context) do
    template = engine.templates[:chain_of_thought]
    
    template
    |> String.replace("{{problem}}", problem)
    |> String.replace("{{context}}", format_financial_context(context))
    |> String.replace("{{reasoning_steps}}", get_reasoning_framework(problem))
  end

  @doc """
  Create a few-shot learning prompt with financial examples.
  """
  def create_few_shot_prompt(engine, task_type, examples_count \\ 3) do
    examples = get_few_shot_examples(engine, task_type, examples_count)
    template = engine.templates[:few_shot]
    
    formatted_examples = 
      examples
      |> Enum.map(&format_example/1)
      |> Enum.join("\n\n")
    
    template
    |> String.replace("{{examples}}", formatted_examples)
    |> String.replace("{{task_description}}", get_task_description(task_type))
  end

  @doc """
  Create a RAG-enhanced prompt with retrieved context.
  """
  def create_rag_prompt(engine, query, retrieved_docs, user_context) do
    template = engine.templates[:rag_enhanced]
    
    formatted_docs = format_retrieved_documents(retrieved_docs)
    financial_summary = summarize_financial_context(user_context)
    
    template
    |> String.replace("{{query}}", query)
    |> String.replace("{{retrieved_context}}", formatted_docs)
    |> String.replace("{{user_financial_context}}", financial_summary)
  end

  # Private Functions

  defp load_prompt_templates() do
    %{
      conversational: """
      You are a sophisticated financial advisor AI assistant specializing in personal finance management. 
      You have access to the user's financial data and should provide personalized, actionable advice.

      User's Financial Context:
      {{financial_context}}

      Conversation History:
      {{conversation_history}}

      Current Question: {{message}}

      Please provide a helpful, accurate, and personalized response. Consider the user's specific financial situation, goals, and risk tolerance. If you need clarification, ask specific questions.

      Response:
      """,

      chain_of_thought: """
      You are an expert financial analyst. Solve this step-by-step using clear reasoning.

      Problem: {{problem}}
      
      Financial Context: {{context}}
      
      Reasoning Framework: {{reasoning_steps}}
      
      Let me think through this step by step:
      
      Step 1: Understand the situation
      Step 2: Analyze the financial data
      Step 3: Consider the options
      Step 4: Evaluate risks and benefits
      Step 5: Provide recommendation with rationale
      
      Solution:
      """,

      few_shot: """
      Here are examples of how to handle similar financial questions:

      {{examples}}

      Task: {{task_description}}

      Now, please handle the following:
      """,

      rag_enhanced: """
      You are a financial advisor with access to comprehensive financial knowledge and the user's personal financial data.

      Retrieved Financial Knowledge:
      {{retrieved_context}}

      User's Financial Situation:
      {{user_financial_context}}

      Question: {{query}}

      Based on both the retrieved knowledge and the user's specific financial situation, provide a detailed, personalized response:
      """,

      financial_analysis: """
      Perform a comprehensive financial analysis based on the following data:

      Analysis Type: {{analysis_type}}
      User Data: {{user_data}}
      
      Please provide:
      1. Current Financial Health Assessment
      2. Key Insights and Patterns
      3. Risks and Opportunities
      4. Specific Recommendations
      5. Action Plan with Timeline
      
      Analysis:
      """,

      goal_planning: """
      Help create a detailed financial plan for achieving the following goal:

      Goal: {{goal_description}}
      Target Amount: {{target_amount}}
      Timeline: {{timeline}}
      Current Savings: {{current_savings}}
      Monthly Income: {{monthly_income}}
      Monthly Expenses: {{monthly_expenses}}

      Please provide:
      1. Feasibility Assessment
      2. Required Monthly Savings
      3. Investment Strategy Recommendations
      4. Risk Considerations
      5. Milestone Tracking Plan

      Plan:
      """,

      debt_optimization: """
      Analyze the debt situation and provide optimization recommendations:

      Total Debt: {{total_debt}}
      Debt Details: {{debt_breakdown}}
      Available Cash Flow: {{available_cash_flow}}
      Credit Score: {{credit_score}}

      Please provide:
      1. Debt Payoff Strategy (Avalanche vs Snowball)
      2. Consolidation Opportunities
      3. Refinancing Options
      4. Timeline to Debt Freedom
      5. Impact on Credit Score

      Recommendations:
      """
    }
  end

  defp load_financial_personas() do
    %{
      conservative: %{
        risk_tolerance: :low,
        investment_horizon: :long_term,
        personality: "risk-averse, security-focused, prefers stable returns"
      },
      moderate: %{
        risk_tolerance: :moderate,
        investment_horizon: :medium_term,
        personality: "balanced approach, willing to take calculated risks"
      },
      aggressive: %{
        risk_tolerance: :high,
        investment_horizon: :long_term,
        personality: "growth-focused, comfortable with volatility"
      },
      income_focused: %{
        risk_tolerance: :low_to_moderate,
        investment_horizon: :any,
        personality: "prioritizes regular income over growth"
      }
    }
  end

  defp load_prompt_strategies() do
    %{
      conversational: %{
        temperature: 0.7,
        techniques: [:context_aware, :personalized],
        max_tokens: 1000
      },
      analytical: %{
        temperature: 0.3,
        techniques: [:chain_of_thought, :structured_reasoning],
        max_tokens: 1500
      },
      creative: %{
        temperature: 0.8,
        techniques: [:scenario_generation, :brainstorming],
        max_tokens: 1200
      },
      precise: %{
        temperature: 0.1,
        techniques: [:calculation_focused, :fact_based],
        max_tokens: 800
      }
    }
  end

  defp load_few_shot_examples() do
    %{
      budgeting: [
        %{
          input: "I'm spending too much on dining out. How can I reduce this expense?",
          output: "Based on your dining expenses of $400/month, here's a plan: 1) Set a monthly dining budget of $200 2) Meal prep on Sundays 3) Use the 'one dining out per week' rule 4) Try cooking challenges to make it fun. This saves $200/month = $2,400/year."
        },
        %{
          input: "My monthly income is $5000 and expenses are $4500. Am I saving enough?",
          output: "Your savings rate is 10% ($500/$5000), which meets the minimum recommendation. However, aim for 20% if possible. Consider: 1) Review expenses for cuts 2) Increase income through side hustle 3) Automate savings to ensure consistency."
        }
      ],
      
      investment: [
        %{
          input: "Should I invest in individual stocks or index funds?",
          output: "For most investors, index funds are better because: 1) Instant diversification 2) Lower fees (0.1-0.5% vs 1-2%) 3) Less time required 4) Better long-term performance than 90% of actively managed funds. Consider 80% index funds, 20% individual stocks if you enjoy stock picking."
        }
      ],
      
      debt_management: [
        %{
          input: "I have $10k credit card debt at 18% APR and $20k student loan at 5%. Which should I pay off first?",
          output: "Pay minimums on both, but focus extra payments on credit card debt due to higher interest (18% vs 5%). This is the 'avalanche method' - mathematically optimal. You'll save significant interest. Credit card debt costs $1,800/year in interest vs $1,000/year for student loan."
        }
      ]
    }
  end

  defp build_base_prompt(engine, strategy, context) do
    case context.prompt_strategy do
      :chain_of_thought ->
        create_cot_prompt(engine, context.message, context)
      :few_shot ->
        create_few_shot_prompt(engine, detect_task_type(context.message))
      :rag_enhanced ->
        create_rag_prompt(engine, context.message, [], context)
      _ ->
        template = engine.templates[:conversational]
        template
        |> String.replace("{{message}}", context.message)
    end
  end

  defp enhance_with_context(prompt, context) do
    prompt
    |> String.replace("{{financial_context}}", format_financial_context(context.financial_context))
    |> String.replace("{{conversation_history}}", format_conversation_history(context.conversation_history))
    |> String.replace("{{user_id}}", to_string(context.user_id))
  end

  defp apply_prompt_techniques(prompt, strategy, engine) do
    strategy_config = engine.prompt_strategies[strategy] || engine.prompt_strategies[:conversational]
    
    techniques = strategy_config[:techniques] || []
    
    prompt
    |> maybe_add_reasoning_structure(Enum.member?(techniques, :structured_reasoning))
    |> maybe_add_persona(Enum.member?(techniques, :personalized), engine)
    |> maybe_add_constraints(Enum.member?(techniques, :calculation_focused))
  end

  defp maybe_add_reasoning_structure(prompt, true) do
    reasoning_structure = """
    
    Please structure your response as follows:
    1. **Analysis**: Break down the key components
    2. **Calculation**: Show any relevant math step-by-step
    3. **Recommendations**: Provide specific, actionable advice
    4. **Timeline**: Suggest implementation steps
    5. **Monitoring**: How to track progress
    """
    
    prompt <> reasoning_structure
  end
  defp maybe_add_reasoning_structure(prompt, false), do: prompt

  defp maybe_add_persona(prompt, true, engine) do
    # This could be enhanced to detect user's risk profile from their data
    persona_addition = """
    
    Important: Tailor your advice to be appropriate for someone with moderate risk tolerance who values both growth and security.
    """
    
    prompt <> persona_addition
  end
  defp maybe_add_persona(prompt, false, _engine), do: prompt

  defp maybe_add_constraints(prompt, true) do
    constraints = """
    
    Requirements:
    - Show all calculations step-by-step
    - Provide specific dollar amounts where applicable
    - Include time-based projections
    - State any assumptions clearly
    """
    
    prompt <> constraints
  end
  defp maybe_add_constraints(prompt, false), do: prompt

  defp format_financial_context(nil), do: "No financial context available."
  defp format_financial_context(context) when is_map(context) do
    """
    Financial Summary:
    - Net Worth: #{format_money(context[:net_worth])}
    - Assets: #{length(context[:assets] || [])} items
    - Debts: #{length(context[:debts] || [])} obligations
    - Goals: #{length(context[:goals] || [])} active goals
    """
  end

  defp format_conversation_history([]), do: "No previous conversation."
  defp format_conversation_history(history) when is_list(history) do
    history
    |> Enum.take(5)  # Last 5 exchanges
    |> Enum.map(fn exchange ->
      "User: #{exchange.user_message}\nAssistant: #{exchange.assistant_response}"
    end)
    |> Enum.join("\n\n")
  end

  defp format_money(nil), do: "Not available"
  defp format_money(amount), do: Money.to_string(amount)

  defp get_reasoning_framework(problem) do
    cond do
      String.contains?(problem, ["invest", "portfolio"]) ->
        "1. Assess risk tolerance 2. Determine time horizon 3. Evaluate asset allocation 4. Consider fees and taxes 5. Review diversification"
      
      String.contains?(problem, ["debt", "loan", "payoff"]) ->
        "1. List all debts with rates 2. Calculate minimum payments 3. Determine available cash flow 4. Choose payoff strategy 5. Create timeline"
      
      String.contains?(problem, ["budget", "spending"]) ->
        "1. Track current spending 2. Categorize expenses 3. Identify priorities 4. Set realistic targets 5. Implement tracking system"
      
      true ->
        "1. Gather relevant information 2. Analyze current situation 3. Identify options 4. Evaluate pros/cons 5. Make recommendation"
    end
  end

  defp detect_task_type(message) do
    cond do
      String.contains?(String.downcase(message), ["budget", "spend", "expense"]) -> :budgeting
      String.contains?(String.downcase(message), ["invest", "stock", "fund"]) -> :investment
      String.contains?(String.downcase(message), ["debt", "loan", "payoff"]) -> :debt_management
      true -> :general
    end
  end

  defp get_few_shot_examples(engine, task_type, count) do
    engine.few_shot_examples
    |> Map.get(task_type, [])
    |> Enum.take(count)
  end

  defp format_example(example) do
    """
    Example:
    User: #{example.input}
    Assistant: #{example.output}
    """
  end

  defp get_task_description(:budgeting), do: "Help with budgeting and expense management"
  defp get_task_description(:investment), do: "Provide investment advice and portfolio guidance"
  defp get_task_description(:debt_management), do: "Assist with debt optimization and payoff strategies"
  defp get_task_description(_), do: "Provide general financial advice"

  defp format_retrieved_documents([]), do: "No additional context retrieved."
  defp format_retrieved_documents(docs) when is_list(docs) do
    docs
    |> Enum.map(fn doc -> "- #{doc.content}" end)
    |> Enum.join("\n")
  end

  defp summarize_financial_context(context) do
    format_financial_context(context)
  end
end