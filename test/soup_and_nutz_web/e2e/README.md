# End-to-End Testing Guide

This directory contains end-to-end (E2E) tests for the Soup & Nutz financial planner application using Hound and ChromeDriver.

## Overview

Our E2E testing stack consists of:
- **Hound**: Elixir library for browser automation
- **ChromeDriver**: WebDriver for Chrome browser automation
- **ExMachina**: Factory library for test data generation
- **Faker**: Library for generating realistic test data

## Prerequisites

### 1. Install ChromeDriver

#### macOS (using Homebrew):
```bash
brew install chromedriver
```

#### Ubuntu/Debian:
```bash
sudo apt-get install chromium-chromedriver
```

#### Manual Installation:
Download from [ChromeDriver Downloads](https://chromedriver.chromium.org/downloads) and add to your PATH.

### 2. Verify ChromeDriver Installation
```bash
chromedriver --version
```

## Running E2E Tests

### Run All E2E Tests
```bash
mix test.e2e
```

### Run Specific E2E Test File
```bash
mix test test/soup_and_nutz_web/e2e/authentication_test.exs
```

### Run Tests with Tags
```bash
# Run only authentication tests
mix test --only auth

# Run tests excluding slow tests
mix test --exclude slow
```

### Run Tests with Coverage
```bash
mix test.e2e --cover
```

## Test Structure

### Test Files
- `authentication_test.exs` - User registration, login, logout, and profile management
- `financial_instruments_test.exs` - Asset, debt obligation, and cash flow management
- `dashboard_test.exs` - Dashboard functionality and data visualization
- `budget_planner_test.exs` - Budget planning and analysis features
- `debt_payoff_test.exs` - Debt payoff planning and strategies

### Test Categories

#### Authentication Tests
- User registration flow
- Login/logout functionality
- Password reset
- Profile management
- Access control and authorization

#### Financial Instruments Tests
- CRUD operations for assets
- CRUD operations for debt obligations
- CRUD operations for cash flows
- Data validation and error handling
- User data isolation

#### Dashboard Tests
- Financial summary display
- Chart rendering and interaction
- Navigation between sections
- Real-time data updates

#### Planning Tools Tests
- Budget creation and management
- Debt payoff strategy planning
- Financial goal setting and tracking
- Scenario analysis

## Test Data Management

### Factories
We use ExMachina factories to generate test data:

```elixir
# Create a basic user
user = insert(:user)

# Create a user with assets
user_with_assets = insert(:user_with_assets)

# Create a complete user profile
complete_user = insert(:complete_user_profile)
```

### Available Factories
- `:user` - Basic user with email and password
- `:asset` - Financial asset (cash, investment, etc.)
- `:debt_obligation` - Debt (credit card, mortgage, etc.)
- `:cash_flow` - Income or expense
- `:financial_goal` - Savings or investment goal
- `:net_worth_snapshot` - Net worth tracking data

### Custom Factories
- `:user_with_assets` - User with predefined assets
- `:user_with_debts` - User with predefined debts
- `:user_with_cash_flows` - User with income/expenses
- `:complete_user_profile` - User with full financial profile

## Test Helpers

### Authentication Helpers
```elixir
# Sign in a user (creates user if not provided)
user = sign_in_user()

# Sign in with specific user
user = sign_in_user(existing_user)

# Sign out current user
sign_out_user()
```

### Navigation Helpers
```elixir
# Wait for page to load
wait_for_page_to_load()

# Wait for element to appear
wait_for_element({:id, "submit-button"})

# Wait for text to appear
wait_for_text("Success message")
```

### Form Helpers
```elixir
# Fill multiple form fields
fill_form(%{
  "user_email" => "test@example.com",
  "user_password" => "password123"
})

# Submit form
submit_form()
```

### Assertion Helpers
```elixir
# Check current URL path
assert_current_path("/dashboard")

# Check for text presence
assert_text_present("Welcome")

# Check for text absence
assert_text_not_present("Error")

# Check element presence
assert_element_present({:css, ".sidebar"})
```

## Best Practices

### 1. Test Organization
- Group related tests in `describe` blocks
- Use descriptive test names that explain the scenario
- Keep tests independent and isolated

### 2. Data Management
- Use factories for consistent test data
- Clean up data between tests using database sandbox
- Avoid hardcoded values in tests

### 3. Selectors
- Prefer IDs over CSS classes for form elements
- Use semantic selectors when possible
- Avoid brittle selectors that depend on styling

### 4. Waiting Strategies
- Use explicit waits for dynamic content
- Avoid fixed time delays when possible
- Wait for specific conditions rather than arbitrary delays

### 5. Error Handling
- Test both success and failure scenarios
- Verify error messages and validation
- Test edge cases and boundary conditions

## Configuration

### Hound Configuration
Located in `config/test.exs`:

```elixir
config :hound,
  driver: "chrome_driver",
  browser: "chrome_headless",
  app_host: "http://localhost",
  app_port: 4002,
  screenshot_dir: "test/screenshots",
  screenshot_on_failure: true
```

### ChromeDriver Options
```elixir
config :hound,
  chrome_driver: [
    capabilities: %{
      chromeOptions: %{
        args: [
          "headless",
          "disable-gpu",
          "no-sandbox",
          "disable-dev-shm-usage",
          "window-size=1920,1080"
        ]
      }
    }
  ]
```

## Troubleshooting

### Common Issues

#### ChromeDriver Not Found
```bash
# Check if ChromeDriver is in PATH
which chromedriver

# Add to PATH if needed
export PATH=$PATH:/path/to/chromedriver
```

#### Tests Failing Intermittently
- Increase wait timeouts
- Add explicit waits for dynamic content
- Check for race conditions in test setup

#### Screenshots Not Generated
- Ensure screenshot directory exists
- Check file permissions
- Verify Hound configuration

#### Database Connection Issues
- Ensure test database is created
- Check Ecto sandbox configuration
- Verify database migrations are up to date

### Debug Mode
Run tests with debug output:
```bash
mix test --trace
```

### Screenshots
Failed tests automatically generate screenshots in `test/screenshots/` directory.

## CI/CD Integration

### GitHub Actions Example
```yaml
name: E2E Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-elixir@v1
        with:
          elixir-version: '1.14'
          otp-version: '25'
      - run: sudo apt-get install chromium-chromedriver
      - run: mix deps.get
      - run: mix test.e2e
```

### Docker Integration
For Docker-based testing, ensure ChromeDriver is installed in the container:

```dockerfile
# Install ChromeDriver
RUN apt-get update && apt-get install -y chromium-chromedriver
```

## Performance Considerations

### Test Execution Time
- E2E tests are slower than unit tests
- Run in parallel when possible (with caution)
- Use headless mode for faster execution

### Resource Usage
- Chrome instances consume significant memory
- Clean up browser sessions properly
- Monitor system resources during test runs

## Future Enhancements

### Planned Improvements
- Visual regression testing
- Performance testing integration
- Mobile device testing
- Accessibility testing
- Cross-browser testing

### Tools to Consider
- **Wallaby**: Alternative to Hound with better LiveView support
- **Playwright**: Modern browser automation library
- **Cypress**: JavaScript-based E2E testing framework
- **Selenium**: Traditional browser automation

## Contributing

When adding new E2E tests:

1. Follow the existing test structure and naming conventions
2. Use appropriate factories for test data
3. Add comprehensive assertions
4. Include both positive and negative test cases
5. Update this documentation if needed
6. Ensure tests are reliable and not flaky

## Support

For issues with E2E testing:
1. Check the troubleshooting section
2. Review Hound documentation
3. Check ChromeDriver compatibility
4. Verify test environment setup 