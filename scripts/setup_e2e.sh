#!/bin/bash

# E2E Testing Setup Script for Soup & Nutz
# This script helps set up the environment for end-to-end testing with Wallaby

set -e

echo "🚀 Setting up E2E testing environment for Soup & Nutz with Wallaby..."

# Detect operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "📋 Detected OS: $OS"

# Check if Chrome is already installed
if command -v google-chrome &> /dev/null; then
    echo "✅ Google Chrome is already installed:"
    google-chrome --version
elif command -v /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome &> /dev/null; then
    echo "✅ Google Chrome is already installed (macOS):"
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
else
    echo "📥 Installing Google Chrome..."
    
    if [[ "$OS" == "macos" ]]; then
        # macOS installation using Homebrew
        if command -v brew &> /dev/null; then
            brew install --cask google-chrome
        else
            echo "❌ Homebrew not found. Please install Homebrew first:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Linux installation
        if command -v apt-get &> /dev/null; then
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            sudo apt-get update
            sudo apt-get install -y google-chrome-stable
        elif command -v yum &> /dev/null; then
            sudo yum install -y google-chrome-stable
        else
            echo "❌ Unsupported package manager. Please install Google Chrome manually:"
            echo "   https://www.google.com/chrome/"
            exit 1
        fi
    fi
fi

# Check if ChromeDriver is already installed
if command -v chromedriver &> /dev/null; then
    echo "✅ ChromeDriver is already installed:"
    chromedriver --version
else
    echo "📥 Installing ChromeDriver..."
    
    if [[ "$OS" == "macos" ]]; then
        # macOS installation using Homebrew
        if command -v brew &> /dev/null; then
            brew install chromedriver
        else
            echo "❌ Homebrew not found. Please install Homebrew first:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Linux installation
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y chromium-chromedriver
        elif command -v yum &> /dev/null; then
            sudo yum install -y chromium-chromedriver
        else
            echo "❌ Unsupported package manager. Please install ChromeDriver manually:"
            echo "   https://chromedriver.chromium.org/downloads"
            exit 1
        fi
    fi
fi

# Verify ChromeDriver installation
if command -v chromedriver &> /dev/null; then
    echo "✅ ChromeDriver installation verified:"
    chromedriver --version
else
    echo "❌ ChromeDriver installation failed"
    exit 1
fi

# Create screenshots directory
echo "📁 Creating screenshots directory..."
mkdir -p test/screenshots

# Install Elixir dependencies
echo "📦 Installing Elixir dependencies..."
mix deps.get

# Create test database
echo "🗄️  Setting up test database..."
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate

echo ""
echo "🎉 E2E testing environment setup complete!"
echo ""
echo "📚 Next steps:"
echo "   1. Run E2E tests: mix test.e2e"
echo "   2. Run specific test: mix test test/soup_and_nutz_web/e2e/authentication_test.exs"
echo "   3. Run all tests: mix test.all"
echo ""
echo "📖 For more information, see: test/soup_and_nutz_web/e2e/README.md"
echo "" 