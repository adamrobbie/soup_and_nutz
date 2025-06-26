# CSS Usage Guide - Robinhood Design System

## Quick Start Classes

### Financial Cards
```html
<!-- Basic financial card -->
<div class="financial-card">
  <div class="financial-card-header">
    <h3 class="heading-md">Card Title</h3>
  </div>
  <div class="financial-card-content">
    <p>Card content here</p>
  </div>
</div>

<!-- Metric card for KPIs -->
<div class="metric-card hover-lift">
  <div class="flex items-center gap-4">
    <div class="w-12 h-12 bg-gradient-to-br from-profit-500 to-profit-600 rounded-xl flex items-center justify-center">
      <!-- Icon here -->
    </div>
    <div>
      <p class="metric-label">Total Assets</p>
      <p class="metric-value-positive currency-medium">$123,456.78</p>
    </div>
  </div>
</div>
```

### Tables
```html
<div class="financial-table">
  <table class="w-full">
    <thead>
      <tr>
        <th class="financial-table-th">Asset</th>
        <th class="financial-table-th">Value</th>
        <th class="financial-table-th">Change</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="financial-table-td">Apple Stock</td>
        <td class="financial-table-td table-cell-currency text-profit-400">$1,234.56</td>
        <td class="financial-table-td table-cell-positive">+2.3%</td>
      </tr>
    </tbody>
  </table>
</div>
```

### Buttons
```html
<button class="btn-primary">Primary Action</button>
<button class="btn-secondary">Secondary Action</button>
<button class="btn-danger">Delete</button>
<button class="btn-ghost">Cancel</button>
```

### Forms
```html
<div class="space-y-4">
  <div>
    <label class="form-label">Asset Name</label>
    <input type="text" class="form-input" placeholder="Enter asset name">
  </div>
  <div>
    <label class="form-label">Asset Type</label>
    <select class="form-select">
      <option>Choose type...</option>
      <option>Stock</option>
      <option>Bond</option>
    </select>
  </div>
</div>
```

### Status Indicators
```html
<!-- Positive status -->
<span class="status-indicator-positive">Profitable</span>

<!-- Negative status -->
<span class="status-indicator-negative">Loss</span>

<!-- Neutral status -->
<span class="status-indicator-neutral">Pending</span>
```

### Charts
```html
<div class="chart-container">
  <div class="chart-header">
    <h3 class="heading-md">Portfolio Performance</h3>
    <p class="text-muted">Monthly growth trends</p>
  </div>
  <div class="chart-content">
    <canvas id="portfolioChart"></canvas>
  </div>
</div>
```

## Color System

### Financial Colors
- **Profit/Positive**: `text-profit-400`, `bg-profit-500`, `border-profit-300`
- **Loss/Negative**: `text-loss-400`, `bg-loss-500`, `border-loss-300`
- **Neutral**: `text-neutral-300`, `bg-neutral-600`, `border-neutral-400`

### Background Hierarchy
- **Primary Background**: `bg-dark-600`
- **Card Backgrounds**: `bg-dark-100`
- **Hover States**: `bg-dark-200`
- **Input Backgrounds**: `bg-dark-400`

### Text Colors
- **Primary Text**: `text-neutral-100`
- **Secondary Text**: `text-neutral-300`
- **Muted Text**: `text-neutral-400`
- **Accent Text**: `text-brand`

## Typography Classes

### Headings
```html
<h1 class="heading-xl">Extra Large Heading</h1>
<h2 class="heading-lg">Large Heading</h2>
<h3 class="heading-md">Medium Heading</h3>
<h4 class="heading-sm">Small Heading</h4>
```

### Currency Formatting
```html
<span class="currency-large">$1,234,567.89</span>
<span class="currency-medium">$12,345.67</span>
<span class="currency-small">$123.45</span>
```

### Percentages
```html
<span class="percentage-positive">+12.34%</span>
<span class="percentage-negative">-5.67%</span>
```

## Layout Components

### Dashboard Grid
```html
<div class="dashboard-grid">
  <!-- 1-4 columns responsive -->
  <div class="metric-card">Card 1</div>
  <div class="metric-card">Card 2</div>
  <div class="metric-card">Card 3</div>
  <div class="metric-card">Card 4</div>
</div>
```

### Content Containers
```html
<div class="content-container">
  <!-- Max-width container with padding -->
  <div class="dashboard-section">
    <!-- Spaced section -->
  </div>
</div>
```

## Interactive States

### Hover Effects
```html
<div class="financial-card hover-lift">
  <!-- Card with lift animation on hover -->
</div>
```

### Loading States
```html
<div class="skeleton h-4 w-32"></div>
<div class="skeleton h-20 w-full"></div>
```

### Animations
```html
<div class="animate-fade-in">Fade in content</div>
<div class="animate-slide-up">Slide up content</div>
```

## Custom Utilities

### Financial Utilities
```html
<div class="profit-glow">Green glow effect</div>
<div class="loss-glow">Red glow effect</div>
```

## JavaScript Integration

### Chart.js Dark Theme Colors
```javascript
const robinhoodColors = [
  '#00C805', '#FF6B6B', '#0084FF', '#FF8500', '#5C5CE0',
  '#FFD60A', '#34D399', '#F87171', '#8B5CF6', '#06B6D4'
];

// Chart options for dark theme
const darkChartOptions = {
  plugins: {
    legend: {
      labels: {
        color: '#D4D4D4',
        font: { family: 'Inter', size: 12 }
      }
    }
  }
};
```

## Responsive Breakpoints

- **Mobile**: `< 768px` - Single column layouts
- **Tablet**: `768px - 1024px` - Two column layouts  
- **Desktop**: `> 1024px` - Multi-column layouts with sidebar

## Best Practices

1. **Always use financial colors** for monetary values (profit/loss)
2. **Maintain contrast ratios** for accessibility
3. **Use monospace fonts** for currency and numerical data
4. **Apply hover effects** to interactive elements
5. **Test mobile responsiveness** especially for tables
6. **Use status indicators** for categorical data
7. **Follow the component hierarchy** (card > header/content)

This design system provides a complete foundation for building sophisticated financial interfaces that match modern fintech standards.