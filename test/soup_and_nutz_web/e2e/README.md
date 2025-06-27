# End-to-End Testing Guide

This directory contains end-to-end (E2E) tests for the Soup & Nutz financial planner application using Wallaby and ChromeDriver.

## Overview

Our E2E testing stack consists of:
- **Wallaby**: Modern Elixir library for browser automation with excellent LiveView support
- **ChromeDriver**: WebDriver for Chrome browser automation
- **ExMachina**: Factory library for test data generation
- **Faker**: Library for generating realistic test data

## Prerequisites

### 1. Install Google Chrome

#### macOS (using Homebrew):
```bash
brew install --cask google-chrome
```

#### Ubuntu/Debian:
```bash
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update
sudo apt-get install -y google-chrome-stable
```

### 2. Install ChromeDriver

#### macOS (using Homebrew):
```bash
brew install chromedriver
```

#### Ubuntu/Debian:
```bash
sudo apt-get install -y chromium-chromedriver
```

#### Manual Installation:
Download from [ChromeDriver Downloads](https://chromedriver.chromium.org/downloads) and add to your PATH.

### 3. Verify Installation
```bash
google-chrome --version
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
# Run only feature tests
mix test --only feature

# Run tests excluding feature tests
mix test --exclude feature
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
{session, user} = sign_in_user(session)

# Sign in with specific user
{session, user} = sign_in_user(session, existing_user)

# Sign out current user
session = sign_out_user(session)
```

### Navigation Helpers
```elixir
# Wait for page to load
session = wait_for_page_to_load(session)

# Wait for element to appear
session = wait_for_element(session, Query.css(".button"))

# Wait for text to appear
session = wait_for_text(session, "Success message")
```

### Form Helpers
```elixir
# Fill multiple form fields
session = fill_form(session, %{
  "user_email" => "test@example.com",
  "user_password" => "password123"
})

# Submit form
session = submit_form(session)
```

### Assertion Helpers
```elixir
# Check current URL path
session = assert_current_path(session, "/dashboard")

# Check for text presence
session = assert_text_present(session, "Welcome")

# Check for text absence
session = assert_text_not_present(session, "Error")

# Check element presence
session = assert_element_present(session, Query.css(".sidebar"))
```

## Best Practices

### 1. Test Organization
- Use `feature` blocks for Wallaby tests
- Use descriptive test names that explain the scenario
- Keep tests independent and isolated

### 2. Data Management
- Use factories for consistent test data
- Clean up data between tests using database sandbox
- Avoid hardcoded values in tests

### 3. Selectors
- Use Wallaby's Query module for element selection
- Prefer semantic selectors over CSS classes
- Use text-based selectors when possible

### 4. Waiting Strategies
- Use Wallaby's built-in waiting mechanisms
- Avoid fixed time delays
- Wait for specific conditions rather than arbitrary delays

### 5. Error Handling
- Test both success and failure scenarios
- Verify error messages and validation
- Test edge cases and boundary conditions

## Configuration

### Wallaby Configuration
Located in `config/test.exs`:

```elixir
config :wallaby,
  otp_app: :soup_and_nutz,
  base_url: "http://localhost:4002",
  screenshot_dir: "test/screenshots",
  screenshot_on_failure: true,
  chromedriver: [
    headless: true,
    capabilities: %{
      chromeOptions: %{
        args: [
          "--headless=new",
          "--disable-gpu",
          "--no-sandbox",
          "--disable-dev-shm-usage",
          "--window-size=1920,1080"
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

#### Chrome Not Found
```bash
# Check if Chrome is installed
google-chrome --version

# Install Chrome if needed
# See installation instructions above
```

#### Tests Failing Intermittently
- Increase wait timeouts
- Add explicit waits for dynamic content
- Check for race conditions in test setup

#### Screenshots Not Generated
- Ensure screenshot directory exists
- Check file permissions
- Verify Wallaby configuration

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
      - uses: actions/checkout@v3
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.14'
          otp-version: '25'
      - run: |
          sudo apt-get update
          sudo apt-get install -y google-chrome-stable chromium-chromedriver
      - run: mix deps.get
      - run: mix test.e2e
```

### Docker Integration
For Docker-based testing, ensure Chrome and ChromeDriver are installed in the container:

```dockerfile
# Install Chrome and ChromeDriver
RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    chromium-chromedriver
```

## Performance Considerations

### Test Execution Time
- E2E tests are slower than unit tests
- Wallaby provides better performance than Hound
- Use headless mode for faster execution

### Resource Usage
- Chrome instances consume significant memory
- Clean up browser sessions properly
- Monitor system resources during test runs

## Migration from Hound

### Key Differences
- **Session-based API**: Wallaby uses session objects instead of global state
- **Feature-based tests**: Use `feature` instead of `test` for Wallaby tests
- **Query module**: Use `Query.css()`, `Query.text()`, etc. for element selection
- **Pipeline syntax**: Chain operations using the pipe operator

### Migration Checklist
- [x] Replace Hound dependency with Wallaby
- [x] Update test configuration
- [x] Migrate test helpers to session-based API
- [x] Update test files to use `feature` blocks
- [x] Replace element selectors with Query module
- [x] Update CI/CD pipeline
- [x] Update documentation

## Future Enhancements

### Planned Improvements
- Visual regression testing
- Performance testing integration
- Mobile device testing
- Accessibility testing
- Cross-browser testing

### Tools to Consider
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
2. Review Wallaby documentation
3. Check Chrome/ChromeDriver compatibility
4. Verify test environment setup 