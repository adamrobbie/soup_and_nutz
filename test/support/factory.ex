defmodule SoupAndNutz.Factory do
  @moduledoc """
  Factory module for generating test data using ExMachina.
  """

  use ExMachina.Ecto, repo: SoupAndNutz.Repo

  def user_factory do
    %SoupAndNutz.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      date_of_birth: ~D[1990-01-01]
    }
  end

  def asset_factory do
    %SoupAndNutz.FinancialInstruments.Asset{
      asset_name: sequence(:asset_name, &"Asset #{&1}"),
      asset_type: Enum.random(["cash", "investment", "real_estate", "vehicle", "other"]),
      current_value: Decimal.new(Enum.random(1000..100000)),
      currency: "USD",
      user: build(:user)
    }
  end

  def debt_obligation_factory do
    %SoupAndNutz.FinancialInstruments.DebtObligation{
      debt_obligation_name: sequence(:debt_name, &"Debt #{&1}"),
      debt_type: Enum.random(["credit_card", "mortgage", "auto_loan", "student_loan", "personal_loan"]),
      outstanding_balance: Decimal.new(Enum.random(1000..50000)),
      interest_rate: Decimal.new(Enum.random(5..25)),
      minimum_payment: Decimal.new(Enum.random(50..1000)),
      user: build(:user)
    }
  end

  def cash_flow_factory do
    %SoupAndNutz.FinancialInstruments.CashFlow{
      cash_flow_name: sequence(:cash_flow_name, &"Cash Flow #{&1}"),
      cash_flow_type: Enum.random(["income", "expense"]),
      amount: Decimal.new(Enum.random(100..10000)),
      frequency: Enum.random(["weekly", "biweekly", "monthly", "quarterly", "yearly"]),
      user: build(:user)
    }
  end

  def net_worth_snapshot_factory do
    %SoupAndNutz.FinancialInstruments.NetWorthSnapshot{
      snapshot_date: Date.utc_today(),
      total_assets: Decimal.new(Enum.random(50000..500000)),
      total_liabilities: Decimal.new(Enum.random(10000..200000)),
      net_worth: Decimal.new(Enum.random(10000..300000)),
      user: build(:user)
    }
  end

  def financial_goal_factory do
    %SoupAndNutz.FinancialGoals.FinancialGoal{
      goal_name: sequence(:goal_name, &"Goal #{&1}"),
      goal_type: Enum.random(["savings", "debt_payoff", "investment", "purchase"]),
      target_amount: Decimal.new(Enum.random(10000..100000)),
      current_amount: Decimal.new(0),
      target_date: Date.add(Date.utc_today(), Enum.random(30..365)),
      user: build(:user)
    }
  end

  # Custom factories for specific scenarios
  def user_with_assets_factory do
    %SoupAndNutz.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      date_of_birth: ~D[1990-01-01],
      assets: [
        build(:asset, asset_type: "cash", current_value: Decimal.new(10000)),
        build(:asset, asset_type: "investment", current_value: Decimal.new(50000))
      ]
    }
  end

  def user_with_debts_factory do
    %SoupAndNutz.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      date_of_birth: ~D[1990-01-01],
      debt_obligations: [
        build(:debt_obligation, debt_type: "credit_card", outstanding_balance: Decimal.new(5000)),
        build(:debt_obligation, debt_type: "student_loan", outstanding_balance: Decimal.new(25000))
      ]
    }
  end

  def user_with_cash_flows_factory do
    %SoupAndNutz.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      date_of_birth: ~D[1990-01-01],
      cash_flows: [
        build(:cash_flow, cash_flow_type: "income", amount: Decimal.new(5000)),
        build(:cash_flow, cash_flow_type: "expense", amount: Decimal.new(2000))
      ]
    }
  end

  def complete_user_profile_factory do
    %SoupAndNutz.Accounts.User{
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: Bcrypt.hash_pwd_salt("password123"),
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      date_of_birth: ~D[1990-01-01],
      assets: [
        build(:asset, asset_type: "cash", current_value: Decimal.new(15000)),
        build(:asset, asset_type: "investment", current_value: Decimal.new(75000))
      ],
      debt_obligations: [
        build(:debt_obligation, debt_type: "credit_card", outstanding_balance: Decimal.new(3000)),
        build(:debt_obligation, debt_type: "mortgage", outstanding_balance: Decimal.new(200000))
      ],
      cash_flows: [
        build(:cash_flow, cash_flow_type: "income", amount: Decimal.new(6000)),
        build(:cash_flow, cash_flow_type: "expense", amount: Decimal.new(3500))
      ],
      financial_goals: [
        build(:financial_goal, goal_type: "savings", target_amount: Decimal.new(50000))
      ]
    }
  end
end
