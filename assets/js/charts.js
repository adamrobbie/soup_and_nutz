import Chart from "chart.js/auto";

// Chart rendering system for financial data visualization
// This module provides a clean abstraction for rendering charts with different libraries

class ChartRenderer {
  constructor() {
    this.charts = new Map();
    this.currentLibrary = 'chartjs'; // Default to Chart.js
    this.libraries = {
      chartjs: ChartJSRenderer,
      d3: D3Renderer,
      // Add more chart libraries here as needed
    };
  }

  // Initialize the chart renderer
  init() {
    this.setupEventListeners();
    this.renderExistingCharts();
  }

  // Set the chart library to use
  setLibrary(libraryName) {
    if (this.libraries[libraryName]) {
      this.currentLibrary = libraryName;
      this.rerenderAllCharts();
    } else {
      console.warn(`Chart library '${libraryName}' not supported`);
    }
  }

  // Setup event listeners for chart containers
  setupEventListeners() {
    document.addEventListener('DOMContentLoaded', () => {
      this.renderExistingCharts();
    });

    // Listen for LiveView updates
    document.addEventListener('phx:update', () => {
      this.renderNewCharts();
    });
  }

  // Render all existing charts on the page
  renderExistingCharts() {
    const chartContainers = document.querySelectorAll('.chart-container');
    chartContainers.forEach(container => {
      this.renderChart(container);
    });
  }

  // Render only new charts (for LiveView updates)
  renderNewCharts() {
    const chartContainers = document.querySelectorAll('.chart-container:not([data-rendered])');
    chartContainers.forEach(container => {
      this.renderChart(container);
    });
  }

  // Render a specific chart
  renderChart(container) {
    const chartType = container.dataset.chartType;
    const chartData = JSON.parse(container.dataset.chartData);
    const canvas = container.querySelector('.chart-canvas');
    
    if (!canvas) {
      console.warn('No canvas element found for chart');
      return;
    }

    // Mark as rendered to avoid duplicate rendering
    container.setAttribute('data-rendered', 'true');

    // Get the appropriate renderer
    const RendererClass = this.libraries[this.currentLibrary];
    if (!RendererClass) {
      console.error(`Chart library '${this.currentLibrary}' not available`);
      return;
    }

    // Use the canvas id as the chartId
    const chartId = canvas.id || `chart-${Date.now()}-${Math.random()}`;

    // Destroy existing chart instance if it exists
    if (this.charts.has(chartId)) {
      const existingChart = this.charts.get(chartId);
      if (existingChart && existingChart.destroy) {
        existingChart.destroy();
      }
      this.charts.delete(chartId);
    }

    // Create and store the chart
    const chart = new RendererClass(canvas, chartType, chartData);
    this.charts.set(chartId, chart);

    // Store the chart ID on the container for reference
    container.dataset.chartId = chartId;
  }

  // Re-render all charts (useful when switching libraries)
  rerenderAllCharts() {
    // Destroy existing charts
    this.charts.forEach(chart => {
      if (chart.destroy) {
        chart.destroy();
      }
    });
    this.charts.clear();

    // Remove rendered markers
    document.querySelectorAll('.chart-container[data-rendered]').forEach(container => {
      container.removeAttribute('data-rendered');
    });

    // Re-render all charts
    this.renderExistingCharts();
  }

  // Update a specific chart
  updateChart(chartId, newData) {
    const chart = this.charts.get(chartId);
    if (chart && chart.update) {
      chart.update(newData);
    }
  }

  // Destroy a specific chart
  destroyChart(chartId) {
    const chart = this.charts.get(chartId);
    if (chart && chart.destroy) {
      chart.destroy();
      this.charts.delete(chartId);
    }
  }

  // Get chart instance
  getChart(chartId) {
    return this.charts.get(chartId);
  }
}

// Chart.js Renderer
class ChartJSRenderer {
  constructor(canvas, chartType, data) {
    this.canvas = canvas;
    this.chartType = chartType;
    this.data = data;
    this.chart = null;
    this.render();
  }

  render() {
    const ctx = this.canvas.getContext('2d');
    
    // Configure Chart.js options based on chart type
    const options = this.buildOptions();
    
    // Use imported Chart directly
    this.chart = new Chart(ctx, {
      type: this.chartType,
      data: this.data.data,
      options: options
    });
  }

  buildOptions() {
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'top',
          labels: {
            color: '#9CA3AF',
            font: {
              size: 12
            }
          }
        },
        tooltip: {
          enabled: true,
          mode: 'index',
          intersect: false,
          backgroundColor: 'rgba(0, 0, 0, 0.8)',
          titleColor: '#FFFFFF',
          bodyColor: '#FFFFFF',
          borderColor: '#374151',
          borderWidth: 1
        }
      },
      scales: {
        x: {
          display: true,
          grid: {
            color: '#374151',
            drawBorder: false
          },
          ticks: {
            color: '#9CA3AF',
            font: {
              size: 11
            }
          }
        },
        y: {
          display: true,
          grid: {
            color: '#374151',
            drawBorder: false
          },
          ticks: {
            color: '#9CA3AF',
            font: {
              size: 11
            },
            callback: function(value) {
              return '$' + value.toLocaleString();
            }
          }
        }
      }
    };

    // Add type-specific options
    switch (this.chartType) {
      case 'line':
        return this.buildLineOptions(baseOptions);
      case 'bar':
        return this.buildBarOptions(baseOptions);
      case 'pie':
      case 'doughnut':
        return this.buildPieOptions(baseOptions);
      default:
        return baseOptions;
    }
  }

  buildLineOptions(baseOptions) {
    return {
      ...baseOptions,
      elements: {
        point: {
          radius: 4,
          hoverRadius: 6
        },
        line: {
          tension: 0.4
        }
      }
    };
  }

  buildBarOptions(baseOptions) {
    return {
      ...baseOptions,
      elements: {
        bar: {
          borderRadius: 4
        }
      }
    };
  }

  buildPieOptions(baseOptions) {
    return {
      ...baseOptions,
      plugins: {
        ...baseOptions.plugins,
        legend: {
          ...baseOptions.plugins.legend,
          position: 'right'
        }
      }
    };
  }

  update(newData) {
    if (this.chart) {
      this.chart.data = newData.data;
      this.chart.options = this.buildOptions();
      this.chart.update();
    }
  }

  destroy() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  }
}

// D3.js Renderer (placeholder for future implementation)
class D3Renderer {
  constructor(canvas, chartType, data) {
    this.canvas = canvas;
    this.chartType = chartType;
    this.data = data;
    console.log('D3 renderer not yet implemented');
  }

  render() {
    // D3.js implementation would go here
    console.log('D3 renderer not yet implemented');
  }

  update(newData) {
    // D3.js update implementation
  }

  destroy() {
    // D3.js cleanup implementation
  }
}

// Initialize the chart renderer when the script loads
const chartRenderer = new ChartRenderer();

// Export for use in other modules
window.ChartRenderer = ChartRenderer;
window.chartRenderer = chartRenderer;

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    chartRenderer.init();
  });
} else {
  chartRenderer.init();
} 