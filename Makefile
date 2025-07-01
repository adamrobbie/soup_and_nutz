.PHONY: help build up down logs shell db-setup db-reset clean restart deploy release test test-fast test-parallel test-coverage test-file test-local test-watch test-docker test-unit-docker test-file-docker test-prod-docker test-docker-up test-docker-down

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
	@echo ""
	@echo "Testing commands:"
	@echo "  make test       - Run all tests in Docker"
	@echo "  make test-fast  - Run tests with optimized settings for speed"
	@echo "  make test-parallel - Run tests with maximum parallelism"
	@echo "  make test-coverage - Run tests with coverage"
	@echo "  make test-local - Run tests locally (no Docker)"
	@echo "  make test-watch - Run tests in watch mode"
	@echo "  make test-file FILE=path - Run specific test file"
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
# Testing Commands
# =====================

# Run all tests (standard)
test: test-docker-up
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test
	make test-docker-down

# Run tests with optimized settings for speed
test-fast: test-docker-up
	@echo "🚀 Running fast tests with optimized settings..."
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test --max-cases=16 --timeout=30000 --seed=1 --exclude=slow
	make test-docker-down

# Run tests with maximum parallelism
test-parallel: test-docker-up
	@echo "⚡ Running tests with maximum parallelism..."
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test --max-cases=24 --timeout=30000 --seed=1 --exclude=slow
	make test-docker-down

# Run tests with coverage
test-coverage: test-docker-up
	@echo "📊 Running tests with coverage..."
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test --cover --max-cases=16 --timeout=30000
	make test-docker-down

# Run specific test file
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=test/soup_and_nutz_web/controllers/page_controller_test.exs"; \
		exit 1; \
	fi
	@echo "🧪 Running test file: $(FILE)"
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test $(FILE) --max-cases=8 --timeout=30000

# Run tests without Docker (local development)
test-local:
	@echo "🏠 Running tests locally..."
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
	mix test --max-cases=16 --timeout=30000 --seed=1 --exclude=slow

# Run tests with watch mode (for development)
test-watch:
	@echo "👀 Running tests in watch mode..."
	MIX_ENV=test mix ecto.create
	MIX_ENV=test ecto.migrate
	mix test.watch --max-cases=8 --timeout=30000

# Run unit tests in Docker
test-unit-docker: build
	@echo "🧪 Running unit tests in Docker..."
	@docker-compose -f docker-compose.dev.yml --profile test up --abort-on-container-exit --exit-code-from unit-test unit-test
	@docker-compose -f docker-compose.dev.yml --profile test down

# Run tests with specific test file
test-file-docker: build
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file-docker FILE=test/soup_and_nutz_web/e2e/authentication_feature.exs"; \
		exit 1; \
	fi
	@echo "🧪 Running test file $(FILE) in Docker..."
	@docker-compose -f docker-compose.dev.yml --profile test run --rm e2e-test mix test $(FILE)
	@docker-compose -f docker-compose.dev.yml --profile test down

# Build and run tests in production Docker image
test-prod-docker:
	@echo "🧪 Building production image and running tests..."
	@docker build -t soup-and-nutz-test .
	@docker run --rm -e MIX_ENV=test soup-and-nutz-test mix test

test-docker-up:
	docker-compose -f docker-compose.test.yml up -d db_test
	@echo "Waiting for test database to be ready..."
	@until docker exec $$(docker-compose -f docker-compose.test.yml ps -q db_test) pg_isready -U postgres; do \
		sleep 1; \
	done

test-docker-down:
	docker-compose -f docker-compose.test.yml down 