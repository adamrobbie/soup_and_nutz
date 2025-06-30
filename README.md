# Soup & Nutz - Financial Planning Application

[![CI](https://github.com/YOUR_USERNAME/soup_and_nutz/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/soup_and_nutz/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/YOUR_USERNAME/soup_and_nutz/badge.svg?branch=main)](https://coveralls.io/github/YOUR_USERNAME/soup_and_nutz?branch=main)
[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.14-purple.svg)](https://elixir-lang.org)
[![Phoenix](https://img.shields.io/badge/phoenix-~%3E%201.7-orange.svg)](https://phoenixframework.org)

## Project Overview

Soup & Nutz is a comprehensive financial planning application designed to help individuals and families gain complete visibility into their financial health through detailed asset tracking, debt management, and strategic financial planning.

I called it Soup & Nuts because I like both things and I went with a weird naming convention to mess with the AI's honestly.

## Project Goals

### Primary Objectives
1. **Complete Financial Visibility**: Provide users with a comprehensive view of their total net worth by tracking all assets and liabilities
2. **Intelligent Budget Planning**: Generate realistic budgets based on actual financial data and spending patterns
3. **Debt Management & Planning**: Create detailed debt payoff strategies and financial roadmaps
4. **XBRL-Compliant Reporting**: Ensure financial data follows international reporting standards for accuracy and compliance

### Core Features

#### 1. Asset Management
- **Comprehensive Asset Tracking**: Cash, investments, real estate, vehicles, collectibles, and other valuable assets
- **Valuation Methods**: Support for multiple valuation approaches (market value, historical cost, fair value)
- **Risk Assessment**: Categorize assets by risk level and liquidity
- **Performance Tracking**: Monitor asset value changes over time

#### 2. Debt & Liability Management
- **Complete Debt Inventory**: Mortgages, credit cards, student loans, auto loans, and other obligations
- **Payment Scheduling**: Track payment frequencies, due dates, and amounts
- **Interest Rate Analysis**: Monitor interest costs and identify optimization opportunities
- **Debt Consolidation Planning**: Evaluate consolidation strategies

#### 3. Net Worth Analysis
- **Real-time Net Worth Calculation**: Current assets minus total liabilities
- **Historical Tracking**: Monitor net worth changes over time
- **Goal Setting**: Set and track financial milestones
- **Scenario Planning**: Model different financial scenarios

#### 4. Budget Planning
- **Income Tracking**: Monitor all income sources
- **Expense Categorization**: Detailed expense tracking and categorization
- **Cash Flow Analysis**: Monthly and annual cash flow projections
- **Budget Optimization**: AI-powered budget recommendations

#### 5. Financial Reporting
- **XBRL Compliance**: Follow international financial reporting standards
- **Custom Reports**: Generate detailed financial reports
- **Export Capabilities**: Export data in various formats
- **Audit Trail**: Maintain complete transaction history

## Technical Architecture

### Technology Stack
- **Backend**: Elixir/Phoenix (functional programming for financial calculations)
- **Database**: PostgreSQL (ACID compliance for financial data)
- **Frontend**: Phoenix LiveView (real-time updates)
- **Asset Pipeline**: Tailwind CSS + ESBuild
- **Containerization**: Docker & Docker Compose
- **XBRL Standards**: Custom implementation following IFRS/US GAAP

### Domain Models

#### Financial Instruments
- **Assets**: Cash, investments, real estate, vehicles, collectibles, etc.
- **Liabilities**: Mortgages, loans, credit cards, leases, etc.
- **Transactions**: Income, expenses, transfers, payments
- **Valuations**: Multiple valuation methods and measurement bases

#### XBRL Concepts
- **Measurement Bases**: Historical cost, fair value, amortized cost, etc.
- **Business Segments**: Geographic, product, service classifications
- **Regulatory Frameworks**: IFRS, US GAAP, UK GAAP compliance
- **Audit & Compliance**: Audit opinions, compliance statuses, data quality indicators

### Key Features for AI Integration

#### 1. Structured Financial Data
- All financial data follows XBRL taxonomy standards
- Consistent categorization and measurement bases
- Historical data tracking for trend analysis
- Real-time data updates for current financial status

#### 2. Scenario Modeling
- What-if analysis for financial decisions
- Debt payoff optimization scenarios
- Investment allocation strategies
- Retirement planning projections

#### 3. Predictive Analytics
- Cash flow forecasting based on historical patterns
- Budget optimization recommendations
- Risk assessment and mitigation strategies
- Financial goal achievement probability

#### 4. Compliance & Validation
- XBRL rule validation for data accuracy
- Regulatory compliance checking
- Audit trail maintenance
- Data quality indicators

## Development Setup

### Prerequisites
- Docker & Docker Compose
- Elixir 1.18+
- PostgreSQL 15+
- Redis 7+

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd soup_and_nutz

# Start the development environment
make dev

# Access the application
open http://localhost:4000
```

### Development Commands
```bash
make build      # Build Docker images
make up         # Start development environment
make down       # Stop development environment
make logs       # View application logs
make shell      # Access application shell
make db-setup   # Setup database
make db-reset   # Reset database
```

### Testing & Code Quality
```bash
# Run tests
mix test

# Run tests with coverage
mix test.coverage

# Generate HTML coverage report
mix test.coverage.html

# Generate JSON coverage report  
mix test.coverage.json

# Run code quality checks
mix credo

# Run strict code quality checks
mix credo --strict

# Check code formatting
mix format --check-formatted

# Format code
mix format
```

## Data Models

### Asset Schema
- **Asset Identifier**: Unique identifier for each asset
- **Asset Type**: Categorized asset types (cash, investments, real estate, etc.)
- **Valuation**: Fair value, book value, measurement date
- **Risk & Liquidity**: Risk level and liquidity assessment
- **XBRL Metadata**: Reporting entity, period, scenario, validation status

### Debt Obligation Schema
- **Debt Identifier**: Unique identifier for each obligation
- **Debt Type**: Categorized debt types (mortgage, credit card, etc.)
- **Financial Terms**: Principal, outstanding balance, interest rate, payment schedule
- **Risk Assessment**: Risk level and priority for payoff planning
- **XBRL Metadata**: Reporting entity, period, scenario, validation status

## API Endpoints

### Financial Data
- `GET /api/assets` - List all assets
- `GET /api/liabilities` - List all liabilities
- `GET /api/net-worth` - Calculate current net worth
- `POST /api/assets` - Create new asset
- `PUT /api/assets/:id` - Update asset
- `DELETE /api/assets/:id` - Delete asset

### Reporting
- `GET /api/reports/balance-sheet` - Generate balance sheet
- `GET /api/reports/cash-flow` - Generate cash flow statement
- `GET /api/reports/debt-analysis` - Generate debt analysis
- `GET /api/reports/xbrl` - Export XBRL-compliant data

### Planning
- `POST /api/planning/budget` - Generate budget recommendations
- `POST /api/planning/debt-payoff` - Create debt payoff plan
- `POST /api/planning/scenarios` - Run financial scenarios

## XBRL Compliance

The application implements XBRL (eXtensible Business Reporting Language) standards to ensure:
- **Data Consistency**: Standardized financial concepts and measurements
- **Regulatory Compliance**: Adherence to IFRS, US GAAP, and other frameworks
- **Interoperability**: Data can be exchanged with other financial systems
- **Audit Trail**: Complete validation and compliance tracking

### XBRL Concepts Implemented
- Asset and liability classifications
- Measurement bases and valuation methods
- Business segments and geographic regions
- Regulatory frameworks and compliance statuses
- Audit opinions and data quality indicators

## Future Enhancements

### Phase 2 Features
- **Investment Portfolio Management**: Track investment performance and rebalancing
- **Tax Planning**: Tax optimization and planning tools
- **Estate Planning**: Estate planning and inheritance tracking
- **Insurance Management**: Insurance policy tracking and analysis

### Phase 3 Features
- **AI-Powered Insights**: Machine learning for financial recommendations
- **Integration APIs**: Connect with banks, investment accounts, and financial services
- **Mobile Application**: Native mobile app for on-the-go financial management
- **Collaborative Planning**: Multi-user financial planning for families

## Contributing

This project follows standard Elixir/Phoenix development practices:
- Write comprehensive tests for all new features
- Follow XBRL standards for financial data modeling
- Ensure data validation and compliance checking
- Document all API endpoints and data models

## License

[License information to be added]

---

**Note**: This application is designed for personal financial planning and should not be used as a substitute for professional financial advice. Always consult with qualified financial professionals for important financial decisions.
