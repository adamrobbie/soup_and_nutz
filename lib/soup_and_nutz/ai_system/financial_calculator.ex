defmodule SoupAndNutz.AISystem.FinancialCalculator do
  @moduledoc """
  Provides financial calculations using LangChain's calculator tool.

  This module can perform various financial calculations like compound interest,
  loan payments, retirement planning, and more.
  """

  alias LangChain.Tools.Calculator
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias SoupAndNutz.AISystem.ModelProvider

  @doc """
  Calculates compound interest for investments.
  """
  def calculate_compound_interest(principal, rate, time, frequency \\ 12) do
    # Convert annual rate to periodic rate
    periodic_rate = rate / frequency / 100

    # Calculate compound interest
    amount = principal * :math.pow(1 + periodic_rate, frequency * time)
    interest_earned = amount - principal

    %{
      principal: principal,
      rate: rate,
      time: time,
      frequency: frequency,
      final_amount: amount,
      interest_earned: interest_earned,
      total_return: (interest_earned / principal) * 100
    }
  end

  @doc """
  Calculates loan payments using the calculator tool.
  """
  def calculate_loan_payment(principal, rate, term_years) do
    # Monthly interest rate
    monthly_rate = rate / 12 / 100
    num_payments = term_years * 12

    # Payment formula: P = L[c(1 + c)^n]/[(1 + c)^n - 1]
    # Where P = payment, L = loan amount, c = monthly interest rate, n = number of payments

    numerator = monthly_rate * :math.pow(1 + monthly_rate, num_payments)
    denominator = :math.pow(1 + monthly_rate, num_payments) - 1

    monthly_payment = principal * (numerator / denominator)
    total_payments = monthly_payment * num_payments
    total_interest = total_payments - principal

    %{
      principal: principal,
      annual_rate: rate,
      term_years: term_years,
      monthly_payment: monthly_payment,
      total_payments: total_payments,
      total_interest: total_interest
    }
  end

  @doc """
  Calculates retirement savings needs.
  """
  def calculate_retirement_needs(current_age, retirement_age, life_expectancy,
                                current_savings, annual_income, replacement_ratio \\ 0.8) do
    years_to_retirement = retirement_age - current_age
    retirement_years = life_expectancy - retirement_age
    annual_retirement_income = annual_income * replacement_ratio

    # Assume 4% withdrawal rate (25x annual income needed)
    total_needed = annual_retirement_income * 25
    additional_needed = total_needed - current_savings

    # Calculate monthly savings needed
    monthly_savings_needed = if years_to_retirement > 0 do
      # Using compound interest formula to solve for payment
      # FV = PMT * [(1 + r)^n - 1] / r
      # PMT = FV * r / [(1 + r)^n - 1]
      annual_return = 0.07  # 7% annual return
      monthly_return = annual_return / 12
      num_months = years_to_retirement * 12

      if monthly_return > 0 do
        additional_needed * monthly_return / (:math.pow(1 + monthly_return, num_months) - 1)
      else
        additional_needed / num_months
      end
    else
      0
    end

    %{
      current_age: current_age,
      retirement_age: retirement_age,
      life_expectancy: life_expectancy,
      years_to_retirement: years_to_retirement,
      retirement_years: retirement_years,
      current_savings: current_savings,
      annual_income: annual_income,
      annual_retirement_income: annual_retirement_income,
      total_needed: total_needed,
      additional_needed: additional_needed,
      monthly_savings_needed: monthly_savings_needed
    }
  end

  @doc """
  Calculates debt payoff strategies.
  """
  def calculate_debt_payoff_strategies(debts, monthly_payment) do
    # Sort debts by balance (snowball) and interest rate (avalanche)
    snowball_order = Enum.sort_by(debts, & &1.balance)
    avalanche_order = Enum.sort_by(debts, & &1.interest_rate, :desc)

    # Calculate payoff for both strategies
    snowball_result = calculate_payoff_timeline(snowball_order, monthly_payment)
    avalanche_result = calculate_payoff_timeline(avalanche_order, monthly_payment)

    %{
      snowball_strategy: snowball_result,
      avalanche_strategy: avalanche_result,
            recommendation: if(snowball_result.total_interest < avalanche_result.total_interest, do: "snowball", else: "avalanche")
    }
  end

  @doc """
  Calculates budget allocation using the 50/30/20 rule.
  """
  def calculate_budget_allocation(monthly_income) do
    needs = monthly_income * 0.5
    wants = monthly_income * 0.3
    savings = monthly_income * 0.2

    %{
      monthly_income: monthly_income,
      needs_50_percent: needs,
      wants_30_percent: wants,
      savings_20_percent: savings,
      annual_savings: savings * 12
    }
  end

    @doc """
  Uses LangChain's calculator tool for complex financial calculations.
  """
  def calculate_with_ai(calculation_description) do
    case ModelProvider.get_model() do
      {:ok, llm} ->
        # Create a chain with the calculator tool
        chain = LLMChain.new!(%{
          llm: llm,
          system_message: """
          You are a financial calculator assistant. Use the calculator tool to perform financial calculations.

          When given a calculation request:
          1. Break it down into mathematical steps
          2. Use the calculator tool for each step
          3. Provide the final result with explanation

          Common financial calculations:
          - Compound interest: P(1 + r/n)^(nt)
          - Loan payments: P[r(1+r)^n]/[(1+r)^n-1]
          - Present value: FV/(1+r)^n
          - Future value: PV(1+r)^n
          """
        })

        # Add the calculator tool
        chain_with_tool = LLMChain.add_tools(chain, [Calculator.new!()])

        # Add the user's calculation request
        chain_with_message = LLMChain.add_message(chain_with_tool, Message.new_user!(calculation_description))

        case LLMChain.run(chain_with_message, mode: :while_needs_response) do
          {:ok, result} ->
            # Extract the final response
            messages = Map.get(result, :messages, [])
            response = case List.last(messages) do
              %{content: content} -> content
              _ -> "Calculation completed"
            end
            {:ok, response}
          {:error, reason} ->
            {:error, "Calculation failed: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to get model: #{inspect(reason)}"}
    end
  end

  # Private helper functions

  defp calculate_payoff_timeline(debts, monthly_payment) do
    # Simulate payoff timeline
    {months, total_interest} = Enum.reduce(debts, {0, 0}, fn debt, {total_months, total_interest} ->
      remaining_balance = debt.balance
      monthly_interest_rate = debt.interest_rate / 12 / 100

      {months_for_debt, interest_paid} = calculate_debt_payoff_months(
        remaining_balance,
        monthly_payment,
        monthly_interest_rate
      )

      {total_months + months_for_debt, total_interest + interest_paid}
    end)

    %{
      total_months: months,
      total_interest: total_interest,
      years: months / 12
    }
  end

  defp calculate_debt_payoff_months(balance, monthly_payment, monthly_interest_rate) do
    if monthly_payment <= balance * monthly_interest_rate do
      # Payment is less than interest - debt will never be paid off
      {999, balance * monthly_interest_rate}
    else
      # Calculate months to payoff
      months = :math.log(monthly_payment / (monthly_payment - balance * monthly_interest_rate)) /
               :math.log(1 + monthly_interest_rate)

      # Calculate total interest paid
      total_payments = months * monthly_payment
      interest_paid = total_payments - balance

      {round_up(months), interest_paid}
    end
  end

  defp round_up(x) do
    Kernel.trunc(x + 0.999999)
  end
end
