defmodule SoupAndNutz.AI.MockOpenAIClient do
  def chat_completion(opts) do
    # Extract the messages to determine the type of request
    messages = Keyword.get(opts, :messages, [])

    # Check if this is an intent classification request
    if Enum.any?(messages, fn msg ->
      String.contains?(msg.content || "", "intent classifier") or
      String.contains?(msg.content || "", "Analyze the user input")
    end) do
      # Determine intent based on content
      content = messages |> Enum.map(fn msg -> msg.content || "" end) |> Enum.join(" ")

      intent = cond do
        # Debt optimization analysis
        String.match?(content, ~r/\b(debt.*optimization|optimize.*debt|help.*optimize.*debt)\b/i) ->
          %{"type" => "analyze", "entity" => "debt_optimization", "confidence" => 0.95}

        # Asset creation (check before debt creation)
        String.match?(content, ~r/\b(create|add|new).*asset\b/i) ->
          %{"type" => "create", "entity" => "asset", "confidence" => 0.95}

        # Debt creation
        String.match?(content, ~r/\b(create|add|new).*debt\b/i) or String.match?(content, ~r/credit.*card/i) ->
          %{"type" => "create", "entity" => "debt", "confidence" => 0.95}

        # Default to asset creation
        true ->
          %{"type" => "create", "entity" => "asset", "confidence" => 0.95}
      end

      # Return intent classification response
      {:ok, %{
        choices: [
          %{
            message: %{
              content: Jason.encode!(intent)
            }
          }
        ]
      }}
    else
      # Check the content to determine what type of response to return
      content = messages |> Enum.map(fn msg -> msg.content || "" end) |> Enum.join(" ")
      lc_content = String.downcase(content)

      cond do
        # Debt optimization analysis extraction
        String.match?(content, ~r/\b(optimize.*debt|debt.*optimization|help.*optimize.*debt)\b/i) ->
          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(%{
                    "type" => "debt_optimization_analysis",
                    "debts" => [
                      %{"debt_name" => "Credit Card", "outstanding_balance" => "5000", "interest_rate" => "18"}
                    ],
                    "suggestions" => ["Pay off high-interest debts first", "Consider consolidation"]
                  })
                }
              }
            ]
          }}

        # Asset creation extraction (only if not a debt/credit card prompt)
        String.match?(lc_content, ~r/\basset\b/) and not String.match?(lc_content, ~r/\bdebt\b/) and not String.contains?(lc_content, "credit card") and String.match?(lc_content, ~r/\b(create|add|new).*asset\b/) and String.contains?(content, "Extract") ->
          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(%{
                    "type" => "asset",
                    "data" => %{
                      "asset_name" => "Test Asset",
                      "asset_type" => "InvestmentSecurities",
                      "fair_value" => "10000",
                      "currency_code" => "USD"
                    },
                    "confidence" => 0.95,
                    "missing_fields" => [],
                    "suggestions" => []
                  })
                }
              }
            ]
          }}

        # Debt creation extraction (only if not an asset prompt)
        ((String.match?(lc_content, ~r/\bdebt\b/) or String.contains?(lc_content, "credit card")) and not String.match?(lc_content, ~r/\basset\b/) and String.match?(lc_content, ~r/\b(create|add|new).*debt\b/)) or (String.contains?(lc_content, "credit card") and String.contains?(lc_content, "balance") and String.contains?(lc_content, "interest")) and String.contains?(content, "Extract") ->
          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(%{
                    "type" => "debt",
                    "data" => %{
                      "debt_name" => "Credit Card",
                      "principal_amount" => "5000",
                      "debt_type" => "CreditCard",
                      "currency_code" => "USD",
                      "outstanding_balance" => "5000"
                    },
                    "confidence" => 0.95,
                    "missing_fields" => [],
                    "suggestions" => []
                  })
                }
              }
            ]
          }}

        # Data extraction for clarification responses
        String.contains?(content, "Extract the following fields") ->
          # Determine entity type from the prompt
          entity = cond do
            String.contains?(content, "debt") -> "debt"
            String.contains?(content, "asset") -> "asset"
            true -> "asset"
          end

          extracted_data = case entity do
            "asset" ->
              %{"asset_name" => "Test Asset", "asset_type" => "InvestmentSecurities", "fair_value" => "10000"}
            "debt" ->
              %{"debt_name" => "Test Loan", "principal_amount" => "5000", "debt_type" => "PersonalLoan"}
          end

          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(extracted_data)
                }
              }
            ]
          }}

        # Goal creation extraction
        String.contains?(content, "goal") and String.contains?(content, "Extract") ->
          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(%{
                    "type" => "goal",
                    "data" => %{
                      "goal_name" => "Save for house",
                      "target_amount" => "50000",
                      "target_date" => "2025-12-31"
                    },
                    "confidence" => 0.95,
                    "missing_fields" => [],
                    "suggestions" => []
                  })
                }
              }
            ]
          }}

        # Default to asset creation
        true ->
          {:ok, %{
            choices: [
              %{
                message: %{
                  content: Jason.encode!(%{
                    "type" => "asset",
                    "data" => %{
                      "asset_name" => "Test Asset",
                      "asset_type" => "InvestmentSecurities",
                      "fair_value" => "10000",
                      "currency_code" => "USD"
                    },
                    "confidence" => 0.95,
                    "missing_fields" => [],
                    "suggestions" => []
                  })
                }
              }
            ]
          }}
      end
    end
  end

  def embeddings(_opts) do
    {:ok, %{
      data: [
        %{embedding: [0.1, 0.2, 0.3, 0.4, 0.5]}
      ]
    }}
  end
end
