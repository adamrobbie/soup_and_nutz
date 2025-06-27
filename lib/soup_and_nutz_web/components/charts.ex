defmodule SoupAndNutzWeb.Components.Charts do
  @moduledoc """
  Chart abstraction system for financial data visualization.

  This module provides a clean separation between data preparation and chart rendering,
  making it easy to switch between different chart libraries.
  """

  use Phoenix.Component

  @doc """
  Renders a line chart with the given data and options.
  """
  def line_chart(assigns) do
    chart_data = prepare_line_chart_data(assigns.data, assigns.options)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="chart-container" data-chart-type="line" data-chart-data={Jason.encode!(@chart_data)}>
      <canvas id={@id} class="chart-canvas"></canvas>
    </div>
    """
  end

  @doc """
  Renders a bar chart with the given data and options.
  """
  def bar_chart(assigns) do
    chart_data = prepare_bar_chart_data(assigns.data, assigns.options)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="chart-container" data-chart-type="bar" data-chart-data={Jason.encode!(@chart_data)}>
      <canvas id={@id} class="chart-canvas"></canvas>
    </div>
    """
  end

  @doc """
  Renders a pie chart with the given data and options.
  """
  def pie_chart(assigns) do
    chart_data = prepare_pie_chart_data(assigns.data, assigns.options)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="chart-container" data-chart-type="pie" data-chart-data={Jason.encode!(@chart_data)}>
      <canvas id={@id} class="chart-canvas"></canvas>
    </div>
    """
  end

  @doc """
  Renders a doughnut chart with the given data and options.
  """
  def doughnut_chart(assigns) do
    chart_data = prepare_doughnut_chart_data(assigns.data, assigns.options)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="chart-container" data-chart-type="doughnut" data-chart-data={Jason.encode!(@chart_data)}>
      <canvas id={@id} class="chart-canvas"></canvas>
    </div>
    """
  end

  @doc """
  Renders a stacked bar chart with the given data and options.
  """
  def stacked_bar_chart(assigns) do
    chart_data = prepare_stacked_bar_chart_data(assigns.data, assigns.options)

    assigns = assign(assigns, :chart_data, chart_data)

    ~H"""
    <div class="chart-container" data-chart-type="stacked-bar" data-chart-data={Jason.encode!(@chart_data)}>
      <canvas id={@id} class="chart-canvas"></canvas>
    </div>
    """
  end

  # Data preparation functions

  defp prepare_line_chart_data(data, options) do
    %{
      type: "line",
      data: %{
        labels: extract_labels(data),
        datasets: extract_line_datasets(data, options)
      },
      options: build_chart_options(options)
    }
  end

  defp prepare_bar_chart_data(data, options) do
    %{
      type: "bar",
      data: %{
        labels: extract_labels(data),
        datasets: extract_bar_datasets(data, options)
      },
      options: build_chart_options(options)
    }
  end

  defp prepare_pie_chart_data(data, options) do
    %{
      type: "pie",
      data: %{
        labels: extract_labels(data),
        datasets: [extract_pie_dataset(data, options)]
      },
      options: build_chart_options(options)
    }
  end

  defp prepare_doughnut_chart_data(data, options) do
    %{
      type: "doughnut",
      data: %{
        labels: extract_labels(data),
        datasets: [extract_pie_dataset(data, options)]
      },
      options: build_chart_options(options)
    }
  end

  defp prepare_stacked_bar_chart_data(data, options) do
    %{
      type: "bar",
      data: %{
        labels: extract_labels(data),
        datasets: extract_stacked_bar_datasets(data, options)
      },
      options: build_stacked_chart_options(options)
    }
  end

  # Data extraction helpers

  defp extract_labels(data) when is_list(data) do
    Enum.map(data, fn
      %{label: label} -> label
      %{x: x} -> x
      %{name: name} -> name
      item when is_binary(item) -> item
      _ -> "Unknown"
    end)
  end

  defp extract_labels(_), do: []

  defp extract_line_datasets(data, options) do
    case data do
      %{datasets: datasets} ->
        Enum.map(datasets, &build_line_dataset(&1, options))
      _ ->
        [build_line_dataset(%{data: data, label: options[:label] || "Data"}, options)]
    end
  end

  defp extract_bar_datasets(data, options) do
    case data do
      %{datasets: datasets} ->
        Enum.map(datasets, &build_bar_dataset(&1, options))
      _ ->
        [build_bar_dataset(%{data: data, label: options[:label] || "Data"}, options)]
    end
  end

  defp extract_pie_dataset(data, options) do
    values = case data do
      %{values: values} -> values
      %{data: data_values} -> data_values
      list when is_list(list) -> list
      _ -> []
    end

    colors = options[:colors] || generate_colors(length(values))

    %{
      data: values,
      backgroundColor: colors,
      borderColor: colors,
      borderWidth: 1
    }
  end

  defp extract_stacked_bar_datasets(data, options) do
    case data do
      %{datasets: datasets} ->
        Enum.map(datasets, &build_stacked_bar_dataset(&1, options))
      _ ->
        [build_stacked_bar_dataset(%{data: data, label: options[:label] || "Data"}, options)]
    end
  end

  # Dataset builders

  defp build_line_dataset(dataset, options) do
    %{
      label: dataset[:label] || "Dataset",
      data: extract_values(dataset),
      borderColor: options[:border_color] || "#3B82F6",
      backgroundColor: options[:background_color] || "rgba(59, 130, 246, 0.1)",
      borderWidth: options[:border_width] || 2,
      fill: options[:fill] || false,
      tension: options[:tension] || 0.4
    }
  end

  defp build_bar_dataset(dataset, options) do
    %{
      label: dataset[:label] || "Dataset",
      data: extract_values(dataset),
      backgroundColor: options[:background_color] || "#3B82F6",
      borderColor: options[:border_color] || "#2563EB",
      borderWidth: options[:border_width] || 1
    }
  end

  defp build_stacked_bar_dataset(dataset, options) do
    %{
      label: dataset[:label] || "Dataset",
      data: extract_values(dataset),
      backgroundColor: options[:background_color] || "#3B82F6",
      borderColor: options[:border_color] || "#2563EB",
      borderWidth: options[:border_width] || 1,
      stack: options[:stack] || "stack"
    }
  end

  defp extract_values(dataset) do
    case dataset do
      %{values: values} -> values
      %{data: data_values} -> data_values
      %{y: y_values} -> y_values
      list when is_list(list) -> list
      _ -> []
    end
  end

  # Options builders

  defp build_chart_options(options) do
    %{
      responsive: options[:responsive] || true,
      maintainAspectRatio: options[:maintain_aspect_ratio] || false,
      plugins: build_plugins(options),
      scales: build_scales(options)
    }
  end

  defp build_stacked_chart_options(options) do
    base_options = build_chart_options(options)

    scales = Map.get(base_options, :scales, %{})
    y_scale = Map.get(scales, :y, %{})

    updated_scales = Map.put(scales, :y, Map.put(y_scale, :stacked, true))

    Map.put(base_options, :scales, updated_scales)
  end

  defp build_plugins(options) do
    %{
      legend: %{
        display: options[:show_legend] || true,
        position: options[:legend_position] || "top"
      },
      tooltip: %{
        enabled: options[:show_tooltips] || true,
        mode: options[:tooltip_mode] || "index"
      }
    }
  end

  defp build_scales(options) do
    %{
      x: %{
        display: options[:show_x_axis] || true,
        title: %{
          display: options[:show_x_title] || false,
          text: options[:x_title] || ""
        }
      },
      y: %{
        display: options[:show_y_axis] || true,
        title: %{
          display: options[:show_y_title] || false,
          text: options[:y_title] || ""
        },
        beginAtZero: options[:y_begin_at_zero] || true
      }
    }
  end

  # Utility functions

  defp generate_colors(count) do
    base_colors = [
      "#3B82F6", "#EF4444", "#10B981", "#F59E0B", "#8B5CF6",
      "#06B6D4", "#84CC16", "#F97316", "#EC4899", "#6366F1"
    ]

    Enum.take(Stream.cycle(base_colors), count)
  end
end
