defmodule SoupAndNutzWeb.Components.ChartsTest do
  use SoupAndNutzWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias SoupAndNutzWeb.Components.Charts

  describe "chart components" do
    test "line_chart renders with data" do
      data = %{
        labels: ["Jan", "Feb", "Mar"],
        datasets: [
          %{
            label: "Sales",
            data: [10, 20, 30],
            borderColor: "#3B82F6"
          }
        ]
      }

      html = render_component(&Charts.line_chart/1, %{
        id: "test-chart",
        data: data,
        options: %{}
      })

      assert html =~ "chart-container"
      assert html =~ "data-chart-type=\"line\""
      assert html =~ "test-chart"
    end

    test "bar_chart renders with data" do
      data = %{
        labels: ["A", "B", "C"],
        datasets: [
          %{
            label: "Values",
            data: [1, 2, 3],
            backgroundColor: "#EF4444"
          }
        ]
      }

      html = render_component(&Charts.bar_chart/1, %{
        id: "test-bar",
        data: data,
        options: %{}
      })

      assert html =~ "chart-container"
      assert html =~ "data-chart-type=\"bar\""
      assert html =~ "test-bar"
    end

    test "pie_chart renders with data" do
      data = %{
        labels: ["Red", "Blue", "Green"],
        values: [30, 40, 30]
      }

      html = render_component(&Charts.pie_chart/1, %{
        id: "test-pie",
        data: data,
        options: %{}
      })

      assert html =~ "chart-container"
      assert html =~ "data-chart-type=\"pie\""
      assert html =~ "test-pie"
    end

    test "doughnut_chart renders with data" do
      data = %{
        labels: ["Income", "Expenses"],
        values: [5000, 3000]
      }

      html = render_component(&Charts.doughnut_chart/1, %{
        id: "test-doughnut",
        data: data,
        options: %{}
      })

      assert html =~ "chart-container"
      assert html =~ "data-chart-type=\"doughnut\""
      assert html =~ "test-doughnut"
    end

    test "stacked_bar_chart renders with data" do
      data = %{
        labels: ["Q1", "Q2", "Q3"],
        datasets: [
          %{
            label: "Income",
            data: [1000, 1200, 1100],
            backgroundColor: "#10B981"
          },
          %{
            label: "Expenses",
            data: [800, 900, 850],
            backgroundColor: "#EF4444"
          }
        ]
      }

      html = render_component(&Charts.stacked_bar_chart/1, %{
        id: "test-stacked",
        data: data,
        options: %{}
      })

      assert html =~ "chart-container"
      assert html =~ "data-chart-type=\"stacked-bar\""
      assert html =~ "test-stacked"
    end
  end
end
