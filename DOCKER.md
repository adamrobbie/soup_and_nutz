# Docker Development Setup

This project includes Docker Compose configuration for local development with hot reloading and all necessary services.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Start the development environment:**
   ```bash
   make dev
   ```
   This will:
   - Build the Docker images
   - Start PostgreSQL and Redis
   - Start the Phoenix application
   - Set up the database

2. **Visit your application:**
   - Phoenix app: http://localhost:4000
   - PostgreSQL: localhost:5432
   - Redis: localhost:6379

## Available Commands

### Using Makefile (Recommended)
```bash
make help          # Show all available commands
make build         # Build Docker images
make up            # Start services
make down          # Stop services
make logs          # Show logs
make shell         # Open shell in web container
make db-setup      # Setup database
make db-reset      # Reset database
make clean         # Clean up everything
```

### Using Docker Compose directly
```bash
# Start services
docker-compose -f docker-compose.dev.yml up -d

# Stop services
docker-compose -f docker-compose.dev.yml down

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Execute commands in web container
docker-compose -f docker-compose.dev.yml exec web mix phx.server
docker-compose -f docker-compose.dev.yml exec web mix ecto.setup
```

## Development Workflow

1. **First time setup:**
   ```bash
   make dev
   ```

2. **Daily development:**
   ```bash
   make up    # Start services
   # Make your changes - hot reloading is enabled
   make down  # Stop services when done
   ```

3. **Database operations:**
   ```bash
   make db-setup  # Create and migrate database
   make db-reset  # Reset database (useful for testing)
   ```

4. **Accessing the container:**
   ```bash
   make shell  # Opens a shell in the web container
   ```

## Services

- **Web (Phoenix)**: http://localhost:4000
- **PostgreSQL**: localhost:5432
  - Username: postgres
  - Password: postgres
  - Database: soup_and_nutz_dev
- **Redis**: localhost:6379

## Hot Reloading

The development setup includes hot reloading for:
- Elixir code changes
- Template changes
- Asset changes (CSS/JS)

Changes to your code will automatically trigger recompilation and browser refresh.

## Troubleshooting

### Port conflicts
If you get port conflicts, you can modify the ports in `docker-compose.dev.yml`:
```yaml
ports:
  - "4001:4000"  # Change 4001 to any available port
```

### Database issues
```bash
# Reset the database
make db-reset

# Or manually
docker-compose -f docker-compose.dev.yml exec web mix ecto.drop
docker-compose -f docker-compose.dev.yml exec web mix ecto.setup
```

### Clean slate
```bash
# Remove everything and start fresh
make clean
make dev
```

### View logs
```bash
# All services
make logs

# Specific service
docker-compose -f docker-compose.dev.yml logs -f web
docker-compose -f docker-compose.dev.yml logs -f postgres
```

## Production

For production deployment, use the main `Dockerfile` and `docker-compose.yml` files which are optimized for production builds. 