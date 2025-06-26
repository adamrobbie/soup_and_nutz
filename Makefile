.PHONY: help build up down logs shell db-setup db-reset clean

# Default target
help:
	@echo "Available commands:"
	@echo "  make build      - Build the Docker images"
	@echo "  make up         - Start the development environment"
	@echo "  make down       - Stop the development environment"
	@echo "  make logs       - Show logs from all services"
	@echo "  make shell      - Open a shell in the web container"
	@echo "  make db-setup   - Setup the database (create, migrate, seed)"
	@echo "  make db-reset   - Reset the database (drop, create, migrate, seed)"
	@echo "  make clean      - Remove containers, networks, and volumes"
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