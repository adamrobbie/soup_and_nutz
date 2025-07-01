.PHONY: help build up down logs shell db-setup db-reset clean restart deploy release setup-e2e

# Default target
help:
	@echo "Available commands:"
	@echo "  make build      - Build the Docker images"
	@echo "  make up         - Start the development environment"
	@echo "  make down       - Stop the development environment"
	@echo "  make restart    - Restart the container services"
	@echo "  make logs       - Show logs from all services"
	@echo "  make shell      - Open a shell in the web container"
	@echo "  make db-setup   - Setup the database (create, migrate, seed)"
	@echo "  make db-reset   - Reset the database (drop, create, migrate, seed)"
	@echo "  make clean      - Remove containers, networks, and volumes"
	@echo "  make deploy     - Deploy the application to a Kubernetes cluster"
	@echo "  make release    - Create a new release of the application"
	@echo "  make setup-e2e  - Set up the E2E testing environment"
	@echo ""
	@echo "Services will be available at:"
	@echo "  - Phoenix app: http://localhost:4000"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Redis: localhost:6380"

# Generate mix.lock if it doesn't exist and update dependencies
ensure-mix-lock:
	@if [ ! -f mix.lock ]; then \
		echo "Generating mix.lock..."; \
		mix deps.get; \
	else \
		echo "Updating dependencies..."; \
		mix deps.get; \
	fi

# Setup assets if needed
setup-assets:
	@echo "Setting up assets..."
	@mix assets.setup

# Build the Docker images
build: ensure-mix-lock setup-assets
	docker-compose -f docker-compose.dev.yml build

# Start the development environment
up: ensure-mix-lock setup-assets
	docker-compose -f docker-compose.dev.yml up -d

# Stop the development environment
down:
	docker-compose -f docker-compose.dev.yml down

# Restart the development environment
restart: down up
	@echo "Containers restarted."

# Show logs from all services
logs:
	docker-compose -f docker-compose.dev.yml logs -f

# Show logs from web service only
logs-web:
	docker-compose -f docker-compose.dev.yml logs -f web

# Open a shell in the web container
shell:
	docker-compose -f docker-compose.dev.yml exec web sh

# Setup the database
db-setup:
	docker-compose -f docker-compose.dev.yml exec web mix ecto.setup

# Reset the database
db-reset:
	docker-compose -f docker-compose.dev.yml exec web mix ecto.reset

# Clean up everything
clean:
	docker-compose -f docker-compose.dev.yml down -v --remove-orphans
	docker system prune -f

# Start with database setup
dev: up
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Checking if postgres service is healthy..."
	@until docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U postgres; do \
		echo "Waiting for postgres to be ready..."; \
		sleep 2; \
	done
	@echo "Checking if web service is running..."
	@if ! docker-compose -f docker-compose.dev.yml ps web | grep -q "Up"; then \
		echo "Web service failed to start. Checking logs..."; \
		docker-compose -f docker-compose.dev.yml logs web; \
		exit 1; \
	fi
	@echo "Setting up database..."
	@docker-compose -f docker-compose.dev.yml exec -T web mix ecto.setup
	@echo "Development environment is ready!"
	@echo "  - Phoenix app: http://localhost:4000"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Redis: localhost:6380"

# =====================
# Kubernetes/Helm Deployment
# =====================
deploy:
	@if [ -z "$(ENV)" ] || [ -z "$(ACTION)" ]; then \
		echo "Usage: make deploy ENV=dev ACTION=install"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	VALUES_FILE=helm/soup-and-nutz/values-$(ENV).yaml; \
	if [ ! -f "$$VALUES_FILE" ]; then \
		echo "[ERROR] Values file not found: $$VALUES_FILE"; \
		exit 1; \
	fi; \
	echo "[DEPLOY] Deploying Soup and Nutz to $(ENV) environment"; \
	command -v kubectl >/dev/null 2>&1 || { echo '[ERROR] kubectl is not installed or not in PATH'; exit 1; }; \
	command -v helm >/dev/null 2>&1 || { echo '[ERROR] helm is not installed or not in PATH'; exit 1; }; \
	echo '[INFO] Checking cluster connection...'; \
	kubectl cluster-info >/dev/null 2>&1 || { echo '[ERROR] Cannot connect to Kubernetes cluster'; exit 1; }; \
	echo '[INFO] Adding Helm repositories...'; \
	helm repo add bitnami https://charts.bitnami.com/bitnami; \
	helm repo update; \
	cd helm/soup-and-nutz && helm dependency update && cd ../..; \
	if [ "$(ACTION)" = "install" ]; then \
		echo '[INFO] Installing release: '$$RELEASE_NAME; \
		helm install "$$RELEASE_NAME" ./helm/soup-and-nutz -f "$$VALUES_FILE" --namespace "$(ENV)" --create-namespace --wait --timeout 10m; \
	elif [ "$(ACTION)" = "upgrade" ]; then \
		echo '[INFO] Upgrading release: '$$RELEASE_NAME; \
		helm upgrade "$$RELEASE_NAME" ./helm/soup-and-nutz -f "$$VALUES_FILE" --namespace "$(ENV)" --wait --timeout 10m; \
	else \
		echo '[ERROR] Invalid ACTION. Use install or upgrade.'; \
		exit 1; \
	fi; \
	echo '[INFO] Deployment completed successfully!'; \
	echo '[INFO] Release name: '$$RELEASE_NAME; \
	echo '[INFO] Namespace: $(ENV)'; \
	echo '[INFO] Checking deployment status...'; \
	kubectl get pods -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME"; \
	echo '[INFO] Services:'; \
	kubectl get svc -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME"; \
	if grep -q "enabled: true" "$$VALUES_FILE"; then \
		echo '[INFO] Ingress:'; \
		kubectl get ingress -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME"; \
	fi; \
	echo '[DEPLOY] Deployment to $(ENV) completed successfully!'; \
	echo '[INFO] You can check the logs with: kubectl logs -n $(ENV) -l app.kubernetes.io/instance=$$RELEASE_NAME'

# =====================
# Release Automation
# =====================
release:
	@if [ ! -f mix.exs ]; then \
		echo '[ERROR] mix.exs not found. Please run this from the project root.'; \
		exit 1; \
	fi; \
	CURRENT_VERSION=$$(grep 'version:' mix.exs | sed 's/.*version: "\(.*\)".*/\1/'); \
	echo "[INFO] Current version: $$CURRENT_VERSION"; \
	IFS='.' read -ra VERSION_PARTS <<< "$$CURRENT_VERSION"; \
	MAJOR=$${VERSION_PARTS[0]}; MINOR=$${VERSION_PARTS[1]}; PATCH=$${VERSION_PARTS[2]}; \
	if [ "$(TYPE)" = "major" ]; then \
		NEW_MAJOR=$$((MAJOR + 1)); NEW_MINOR=0; NEW_PATCH=0; \
	elif [ "$(TYPE)" = "minor" ]; then \
		NEW_MAJOR=$$MAJOR; NEW_MINOR=$$((MINOR + 1)); NEW_PATCH=0; \
	else \
		NEW_MAJOR=$$MAJOR; NEW_MINOR=$$MINOR; NEW_PATCH=$$((PATCH + 1)); \
	fi; \
	NEW_VERSION="$$NEW_MAJOR.$$NEW_MINOR.$$NEW_PATCH"; \
	TAG_VERSION="v$$NEW_VERSION"; \
	echo "[INFO] Bumping version to: $$NEW_VERSION ($(TYPE))"; \
	if [ -n "$$(git status --porcelain)" ]; then \
		echo '[WARNING] Working directory is not clean. Please commit or stash changes first.'; \
		git status --short; \
		exit 1; \
	fi; \
	CURRENT_BRANCH=$$(git branch --show-current); \
	if [ "$$CURRENT_BRANCH" != "master" ]; then \
		echo '[WARNING] You are not on the master branch. Current branch: '$$CURRENT_BRANCH; \
		exit 1; \
	fi; \
	echo '[INFO] Updating version in mix.exs...'; \
	sed -i.bak "s/version: \"$$CURRENT_VERSION\"/version: \"$$NEW_VERSION\"/" mix.exs; \
	rm mix.exs.bak; \
	echo '[INFO] Updating CHANGELOG.md...'; \
	TODAY=$$(date +%Y-%m-%d); \
	sed -i.bak "s/## \[Unreleased\]/## [Unreleased]\n\n## [$$NEW_VERSION] - $$TODAY\n\n### Added\n- \n\n### Changed\n- \n\n### Fixed\n- \n\n## [$$CURRENT_VERSION] - $$TODAY/" CHANGELOG.md; \
	rm CHANGELOG.md.bak; \
	echo '[INFO] Committing version bump...'; \
	git add mix.exs CHANGELOG.md; \
	git commit -m "Bump version to $$NEW_VERSION"; \
	echo '[INFO] Creating tag: '$$TAG_VERSION; \
	git tag -a "$$TAG_VERSION" -m "Release $$NEW_VERSION"; \
	echo '[INFO] Pushing changes and tag...'; \
	git push origin master; \
	git push origin "$$TAG_VERSION"; \
	echo '[INFO] Release $$NEW_VERSION has been created and pushed!'; \
	echo '[INFO] GitHub Actions will automatically create a release when the tag is pushed.'; \
	echo '[INFO] You can view the release at: https://github.com/adamrobbie/soup_and_nutz/releases'

# =====================
# E2E Test Environment Setup
# =====================
setup-e2e:
	@echo "🚀 Setting up E2E testing environment for Soup & Nutz with Wallaby..."
	@if [[ "$$(uname)" == "Darwin" ]]; then OS=macos; elif [[ "$$(uname)" == "Linux" ]]; then OS=linux; else echo "❌ Unsupported operating system: $$(uname)"; exit 1; fi; \
	echo "📋 Detected OS: $$OS"; \
	if command -v google-chrome >/dev/null 2>&1; then \
		echo "✅ Google Chrome is already installed:"; \
		google-chrome --version; \
	elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then \
		echo "✅ Google Chrome is already installed (macOS):"; \
		/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version; \
	else \
		echo "📥 Installing Google Chrome..."; \
		if [ "$$OS" = "macos" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install --cask google-chrome; \
			else \
				echo "❌ Homebrew not found. Please install Homebrew first."; \
				echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
				exit 1; \
			fi; \
		elif [ "$$OS" = "linux" ]; then \
			if command -v apt-get >/dev/null 2>&1; then \
				wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -; \
				echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list; \
				sudo apt-get update; \
				sudo apt-get install -y google-chrome-stable; \
			elif command -v yum >/dev/null 2>&1; then \
				sudo yum install -y google-chrome-stable; \
			else \
				echo "❌ Unsupported package manager. Please install Google Chrome manually:"; \
				echo "   https://www.google.com/chrome/"; \
				exit 1; \
			fi; \
		fi; \
	fi; \
	if command -v chromedriver >/dev/null 2>&1; then \
		echo "✅ ChromeDriver is already installed:"; \
		chromedriver --version; \
	else \
		echo "📥 Installing ChromeDriver..."; \
		if [ "$$OS" = "macos" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install chromedriver; \
			else \
				echo "❌ Homebrew not found. Please install Homebrew first."; \
				echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
				exit 1; \
			fi; \
		elif [ "$$OS" = "linux" ]; then \
			if command -v apt-get >/dev/null 2>&1; then \
				sudo apt-get update; \
				sudo apt-get install -y chromium-chromedriver; \
			elif command -v yum >/dev/null 2>&1; then \
				sudo yum install -y chromium-chromedriver; \
			else \
				echo "❌ Unsupported package manager. Please install ChromeDriver manually:"; \
				echo "   https://chromedriver.chromium.org/downloads"; \
				exit 1; \
			fi; \
		fi; \
	fi; \
	if command -v chromedriver >/dev/null 2>&1; then \
		echo "✅ ChromeDriver installation verified:"; \
		chromedriver --version; \
	else \
		echo "❌ ChromeDriver installation failed"; \
		exit 1; \
	fi; \
	echo "📁 Creating screenshots directory..."; \
	mkdir -p test/screenshots; \
	echo "📦 Installing Elixir dependencies..."; \
	mix deps.get; \
	echo "🗄️  Setting up test database..."; \
	MIX_ENV=test mix ecto.create; \
	MIX_ENV=test mix ecto.migrate; \
	echo "\n🎉 E2E testing environment setup complete!\n"; \
	echo "📚 Next steps:"; \
	echo "   1. Run E2E tests: mix test.e2e"; \
	echo "   2. Run specific test: mix test test/soup_and_nutz_web/e2e/authentication_test.exs"; \
	echo "   3. Run all tests: mix test.all"; \
	echo "\n📖 For more information, see: test/soup_and_nutz_web/e2e/README.md\n" 