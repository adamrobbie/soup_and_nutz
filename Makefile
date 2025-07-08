.PHONY: help build up down logs shell db-setup db-reset clean restart deploy release test-docker test-unit-docker test-file-docker test-prod-docker

# Default target
help:
	@echo "Available commands:"
	@echo "  make dev        - Start full development environment"
	@echo "  make up         - Start the development environment"
	@echo "  make down       - Stop the development environment"
	@echo "  make restart    - Restart the container services"
	@echo "  make logs       - Show logs from all services"
	@echo "  make shell      - Open a shell in the web container"
	@echo "  make db-setup   - Setup the database (create, migrate, seed)"
	@echo "  make db-reset   - Reset the database (drop, create, migrate, seed)"
	@echo "  make ai         - Start AI services (Ollama)"
	@echo "  make openllm    - Start OpenLLM service"
	@echo "  make mcp        - Start MCP server"
	@echo "  make ai-all     - Start all AI services (Ollama + OpenLLM + MCP)"
	@echo "  make ai-down    - Stop AI services"
	@echo "  make clean      - Remove containers, networks, and volumes"
	@echo "  make build      - Build the Docker images"
	@echo "  make build-k8s  - Build and push Docker image for Kubernetes"
	@echo "  make deploy     - Deploy the application to a Kubernetes cluster"
	@echo "  make k8s-logs   - Get logs from Kubernetes deployment"
	@echo "  make k8s-status - Get status of Kubernetes deployment"
	@echo "  make k8s-delete - Delete Kubernetes deployment"
	@echo "  make k8s-port-forward - Port forward to Kubernetes services"
	@echo "  make release    - Create a new release of the application"
	@echo ""
	@echo "Services will be available at:"
	@echo "  - Phoenix app: http://localhost:4000"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Redis: localhost:6380"
	@echo "  - Ollama: http://localhost:11434 (run 'make ai' to start)"

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
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build

# Start the development environment
up: ensure-mix-lock setup-assets
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Stop the development environment
down:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

# Restart the development environment
restart: down up
	@echo "Containers restarted."

# Show logs from all services
logs:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

# Show logs from web service only
logs-web:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f web

# Open a shell in the web container
shell:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec web sh

# Setup the database
db-setup:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec web mix ecto.setup

# Reset the database
db-reset:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec web mix ecto.reset

# Clean up everything
clean:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v --remove-orphans
	docker system prune -f

# Start AI services (Ollama, etc.)
ai:
	docker-compose -f docker-compose.yml --profile ai up -d ollama

# Start OpenLLM service
openllm:
	docker-compose -f docker-compose.yml --profile ai up -d openllm

# Start MCP server
mcp:
	docker-compose -f docker-compose.yml --profile ai up -d mcp

# Start all AI services (Ollama + OpenLLM + MCP)
ai-all:
	docker-compose -f docker-compose.yml --profile ai up -d ollama openllm mcp

# Stop AI services
ai-down:
	docker-compose -f docker-compose.yml --profile ai down ollama openllm mcp

# Start with database setup
dev: up
	@echo "Waiting for services to be ready..."
	@sleep 10
	@echo "Checking if postgres service is healthy..."
	@until docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T postgres pg_isready -U postgres; do \
		echo "Waiting for postgres to be ready..."; \
		sleep 2; \
	done
	@echo "Checking if web service is running..."
	@if ! docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps web | grep -q "Up"; then \
		echo "Web service failed to start. Checking logs..."; \
		docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs web; \
		exit 1; \
	fi
	@echo "Setting up database..."
	@docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T web mix ecto.setup
	@echo "Development environment is ready!"
	@echo "  - Phoenix app: http://localhost:4000"
	@echo "  - PostgreSQL: localhost:5433"
	@echo "  - Redis: localhost:6380"
	@echo "  - Ollama: http://localhost:11434 (run 'make ai' to start)"
	@echo "  - OpenLLM: http://localhost:3000 (run 'make openllm' to start)"
	@echo "  - MCP Server: localhost:3002 (run 'make mcp' to start)"

# =====================
# Kubernetes/Helm Deployment
# =====================

# Build and push Docker image for deployment
build-k8s:
	@if [ -z "$(IMAGE_REPO)" ] || [ -z "$(IMAGE_TAG)" ]; then \
		echo "Usage: make build-k8s IMAGE_REPO=adamrobbie549/soup-and-nutz IMAGE_TAG=latest"; \
		exit 1; \
	fi
	@echo "[BUILD] Building production Docker image for Kubernetes deployment..."
	@docker build -f Dockerfile.prod -t $(IMAGE_REPO):$(IMAGE_TAG) .
	@echo "[BUILD] Pushing Docker image..."
	@docker push $(IMAGE_REPO):$(IMAGE_TAG)
	@echo "[BUILD] Image built and pushed: $(IMAGE_REPO):$(IMAGE_TAG)"

# Deploy to Kubernetes
deploy:
	@if [ -z "$(ENV)" ] || [ -z "$(ACTION)" ]; then \
		echo "Usage: make deploy ENV=dev ACTION=install"; \
		echo "Optional: IMAGE_REPO=adamrobbie549/soup-and-nutz IMAGE_TAG=latest"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	VALUES_FILE=helm/soup-and-nutz/values-$(ENV).yaml; \
	if [ ! -f "$$VALUES_FILE" ]; then \
		echo "[ERROR] Values file not found: $$VALUES_FILE"; \
		exit 1; \
	fi; \
	if [ -n "$(IMAGE_REPO)" ] && [ -n "$(IMAGE_TAG)" ]; then \
		echo "[INFO] Using custom image: $(IMAGE_REPO):$(IMAGE_TAG)"; \
		helm upgrade --install "$$RELEASE_NAME" ./helm/soup-and-nutz \
			-f "$$VALUES_FILE" \
			--set image.repository=$(IMAGE_REPO) \
			--set image.tag=$(IMAGE_TAG) \
			--namespace "$(ENV)" \
			--create-namespace \
			--wait \
			--timeout 10m; \
	else \
	echo "[DEPLOY] Deploying Soup and Nutz to $(ENV) environment"; \
	command -v kubectl >/dev/null 2>&1 || { echo '[ERROR] kubectl is not installed or not in PATH'; exit 1; }; \
	command -v helm >/dev/null 2>&1 || { echo '[ERROR] helm is not installed or not in PATH'; exit 1; }; \
	echo '[INFO] Checking cluster connection...'; \
	kubectl cluster-info >/dev/null 2>&1 || { echo '[ERROR] Cannot connect to Kubernetes cluster'; exit 1; }; \
	echo '[INFO] Adding Helm repositories...'; \
	helm repo add bitnami https://charts.bitnami.com/bitnami; \
	helm repo update; \
	cd helm/soup-and-nutz && helm dependency update && cd ../..; \
		echo '[INFO] Using default image from values file'; \
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

# Get Kubernetes logs
k8s-logs:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make k8s-logs ENV=dev"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	kubectl logs -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME" -f

# Get Kubernetes status
k8s-status:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make k8s-status ENV=dev"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	echo "[STATUS] Pods:"; \
	kubectl get pods -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME"; \
	echo "[STATUS] Services:"; \
	kubectl get svc -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME"; \
	echo "[STATUS] Ingress:"; \
	kubectl get ingress -n "$(ENV)" -l "app.kubernetes.io/instance=$$RELEASE_NAME" 2>/dev/null || echo "No ingress found"

# Delete Kubernetes deployment
k8s-delete:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make k8s-delete ENV=dev"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	echo "[DELETE] Deleting release: $$RELEASE_NAME"; \
	helm uninstall "$$RELEASE_NAME" --namespace "$(ENV)" || true; \
	echo "[DELETE] Release deleted"

# Port forward to Kubernetes services
k8s-port-forward:
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make k8s-port-forward ENV=dev"; \
		exit 1; \
	fi
	@RELEASE_NAME=soup-and-nutz-$(ENV); \
	echo "[PORT-FORWARD] Setting up port forwarding..."; \
	echo "Phoenix app: http://localhost:4000"; \
	echo "MCP Server: http://localhost:3002"; \
	echo "PostgreSQL: localhost:5433"; \
	echo "Redis: localhost:6380"; \
	echo "Press Ctrl+C to stop"; \
	kubectl port-forward -n "$(ENV)" svc/$$RELEASE_NAME 4000:80 & \
	kubectl port-forward -n "$(ENV)" svc/$$RELEASE_NAME-mcp 3002:3002 & \
	kubectl port-forward -n "$(ENV)" svc/$$RELEASE_NAME-postgresql 5433:5432 & \
	kubectl port-forward -n "$(ENV)" svc/$$RELEASE_NAME-redis-master 6380:6379 & \
	wait

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
# Docker Testing Commands
# =====================

# Run all tests in Docker
test-docker: build
	@echo "🧪 Running all tests in Docker..."
	@docker-compose -f docker-compose.dev.yml --profile test up --abort-on-container-exit --exit-code-from e2e-test e2e-test unit-test
	@docker-compose -f docker-compose.dev.yml --profile test down

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