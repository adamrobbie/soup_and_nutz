# Docker Setup

This project uses Docker for development and deployment. The setup has been simplified to be more maintainable and easier to use.

## Quick Start

### Development Environment

```bash
# Start the development environment
make dev

# Or manually:
make up
make db-setup
```

This will start:
- **Phoenix app** at http://localhost:4000
- **PostgreSQL** (with pgvector) at localhost:5433
- **Redis** at localhost:6380

### AI Services (Optional)

```bash
# Start Ollama for local LLM models
make ai

# Start OpenLLM for production-ready model serving
make openllm

# Start MCP (Model Context Protocol) server
make mcp

# Start all AI services (Ollama + OpenLLM + MCP)
make ai-all

# Stop AI services
make ai-down
```

## Docker Files

### Core Files
- `docker-compose.yml` - Base services (PostgreSQL, Redis, Ollama)
- `docker-compose.dev.yml` - Development web application
- `Dockerfile` - Production build
- `Dockerfile.dev` - Development build

### Removed Files
- `Dockerfile.test` - Removed (tests run locally)
- `docker-compose.ai.yml` - Consolidated into main compose file

## Available Commands

```bash
# Development
make dev          # Start full development environment
make up           # Start services
make down         # Stop services
make restart      # Restart services
make logs         # Show logs
make shell        # Open shell in web container

# Database
make db-setup     # Setup database (create, migrate, seed)
make db-reset     # Reset database

# AI Services
make ai           # Start Ollama
make ai-down      # Stop Ollama

# Maintenance
make clean        # Remove containers, networks, and volumes
make build        # Build Docker images
```

## Services

### PostgreSQL with pgvector
- **Port**: 5433
- **Database**: soup_and_nutz_dev
- **User**: postgres
- **Password**: postgres
- **Features**: Vector similarity search with pgvector extension

### Redis
- **Port**: 6380
- **Purpose**: Caching and sessions
- **Features**: Health checks and persistent storage

### Ollama (Optional)
- **Port**: 11434
- **Purpose**: Local LLM inference
- **Usage**: Run `make ai` to start
- **Models**: Download models via Ollama API

### OpenLLM (Optional)
- **Port**: 3000
- **Purpose**: Production-ready model serving
- **Usage**: Run `make openllm` to start
- **Features**: OpenAI-compatible API, quantization, monitoring
- **Models**: 100+ models from Hugging Face
- **Advantages**: Better performance, built-in monitoring, model switching

### MCP Server (Optional)
- **Port**: 3002
- **Purpose**: Model Context Protocol server for structured AI tool access
- **Usage**: Run `make mcp` to start
- **Features**: JSON-RPC protocol, conversation access, vector search, system status
- **Tools**: get_conversation, list_conversations, search_conversations, get_system_status, chat
- **Advantages**: Structured data access, tool integration, real-time system monitoring

### Phoenix Web App
- **Port**: 4000
- **Environment**: Development with hot reload
- **Features**: Live code reloading, asset compilation

## Configuration

### Environment Variables

The development environment uses these environment variables:

```bash
DATABASE_URL=postgres://postgres:postgres@postgres:5432/soup_and_nutz_dev
REDIS_URL=redis://redis:6379
PHX_HOST=localhost
SECRET_KEY_BASE=k6p+012lEAfmh1DOQuHtU8tlvULSSuszREFLrm0brzXwJsjfoPmZwKol9zW/bchA
```

### Volumes

- `postgres_data` - PostgreSQL data persistence
- `redis_data` - Redis data persistence
- `ollama_data` - Ollama model storage
- `openllm_data` - OpenLLM model cache and data

## Development Workflow

1. **Start the environment**:
   ```bash
   make dev
   ```

2. **Make changes** to your code (hot reload enabled)

3. **Run tests locally**:
   ```bash
   mix test
   ```

4. **Database operations**:
   ```bash
   make db-setup    # First time setup
   make db-reset    # Reset and recreate
   ```

5. **Stop when done**:
   ```bash
   make down
   ```

## Troubleshooting

### Services won't start
```bash
# Check logs
make logs

# Check specific service
docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs postgres
```

### Database connection issues
```bash
# Reset database
make db-reset

# Check database health
docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec postgres pg_isready -U postgres
```

### Port conflicts
If you have port conflicts, you can modify the ports in `docker-compose.yml`:
- PostgreSQL: Change `5433:5432` to another port
- Redis: Change `6380:6379` to another port
- Phoenix: Change `4000:4000` to another port

### Clean slate
```bash
# Remove everything and start fresh
make clean
make dev
```

## Production

For production deployment, use the main `Dockerfile`:

```bash
# Build production image
docker build -t soup-and-nutz:latest .

# Run with production environment
docker run -p 4000:4000 \
  -e DATABASE_URL=your_production_db_url \
  -e SECRET_KEY_BASE=your_production_secret \
  soup-and-nutz:latest
```

## Architecture

The Docker setup uses a multi-stage approach:

1. **Base services** (`docker-compose.yml`) - Infrastructure services
2. **Development overlay** (`docker-compose.dev.yml`) - Development-specific configuration
3. **Profiles** - Optional services like AI models

This approach allows for:
- Clean separation of concerns
- Easy addition of new services
- Flexible deployment configurations
- Simple local development 