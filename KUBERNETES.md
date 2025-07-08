# Kubernetes Deployment Guide

This guide covers deploying Soup and Nutz to Kubernetes using Helm charts.

## Prerequisites

- Kubernetes cluster (local or cloud)
- `kubectl` configured to access your cluster
- `helm` v3.x installed
- `docker` for building images
- Access to a container registry (Docker Hub, GCR, ECR, etc.)

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build and push the production image
make build-k8s IMAGE_REPO=your-registry/soup-and-nutz IMAGE_TAG=v0.2.0
```

### 2. Deploy to Development Environment

```bash
# Deploy to dev environment
make deploy ENV=dev ACTION=install

# Or with custom image
make deploy ENV=dev ACTION=install IMAGE_REPO=your-registry/soup-and-nutz IMAGE_TAG=v0.2.0
```

### 3. Deploy to Production Environment

```bash
# Deploy to production environment
make deploy ENV=prod ACTION=install

# Or with custom image
make deploy ENV=prod ACTION=install IMAGE_REPO=your-registry/soup-and-nutz IMAGE_TAG=v0.2.0
```

## Available Commands

### Deployment Commands

- `make build-k8s IMAGE_REPO=repo IMAGE_TAG=tag` - Build and push Docker image
- `make deploy ENV=dev ACTION=install` - Deploy to environment
- `make deploy ENV=prod ACTION=upgrade` - Upgrade existing deployment

### Management Commands

- `make k8s-status ENV=dev` - Check deployment status
- `make k8s-logs ENV=dev` - View application logs
- `make k8s-port-forward ENV=dev` - Port forward to services
- `make k8s-delete ENV=dev` - Delete deployment

## Configuration

### Environment-Specific Values

The Helm chart includes environment-specific configuration files:

- `helm/soup-and-nutz/values.yaml` - Default values
- `helm/soup-and-nutz/values-dev.yaml` - Development environment
- `helm/soup-and-nutz/values-prod.yaml` - Production environment

### Key Configuration Options

#### AI System Configuration

```yaml
aiSystem:
  enabled: true
  mcp:
    enabled: true
    port: 3002
  models:
    default: "gpt-3.5-turbo"
    fallback: "gpt-4"
  vectorDb:
    enabled: true
    similarityThreshold: 0.7
    maxResults: 10
```

#### Database Configuration

```yaml
postgresql:
  enabled: true
  auth:
    postgresPassword: "your-password"
    database: "soup_and_nutz_prod"
  primary:
    persistence:
      enabled: true
      size: 20Gi
```

#### Redis Configuration

```yaml
redis:
  enabled: true
  auth:
    enabled: true
    password: "your-redis-password"
  master:
    persistence:
      enabled: true
      size: 5Gi
```

## Services

The deployment creates the following services:

- **Main Application**: Port 80 → 4000 (Phoenix web server)
- **MCP Server**: Port 3002 → 3002 (Model Context Protocol)
- **PostgreSQL**: Port 5432 (Database)
- **Redis**: Port 6379 (Caching/Sessions)

## Port Forwarding

To access services locally:

```bash
make k8s-port-forward ENV=dev
```

This will forward:
- Phoenix app: http://localhost:4000
- MCP Server: http://localhost:3002
- PostgreSQL: localhost:5433
- Redis: localhost:6380

## Environment Variables

The application uses the following environment variables:

### Required
- `SECRET_KEY_BASE` - Phoenix secret key base
- `DATABASE_URL` - PostgreSQL connection string

### AI System (Optional)
- `AI_SYSTEM_ENABLED` - Enable AI system (default: false)
- `AI_DEFAULT_MODEL` - Default AI model (default: gpt-3.5-turbo)
- `AI_FALLBACK_MODEL` - Fallback AI model (default: gpt-4)
- `VECTOR_DB_ENABLED` - Enable vector database (default: false)
- `VECTOR_SIMILARITY_THRESHOLD` - Vector similarity threshold (default: 0.7)
- `VECTOR_MAX_RESULTS` - Maximum vector search results (default: 10)
- `MCP_SERVER_ENABLED` - Enable MCP server (default: false)
- `MCP_SERVER_PORT` - MCP server port (default: 3002)

## Secrets Management

For production deployments, use Kubernetes secrets or external secret management:

```bash
# Create secrets manually
kubectl create secret generic soup-and-nutz-secrets \
  --from-literal=secret-key-base=$(mix phx.gen.secret) \
  --from-literal=database-url="postgresql://user:pass@host/db" \
  -n prod
```

## Monitoring and Logging

### Health Checks

The application includes health checks at `/health` endpoint.

### Metrics

Enable monitoring in production:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   - Ensure image repository is accessible
   - Check image pull secrets if using private registry

2. **Database Connection Issues**
   - Verify PostgreSQL service is running
   - Check database URL format
   - Ensure migrations have run

3. **MCP Server Not Starting**
   - Check if AI system is enabled
   - Verify MCP server port is not in use
   - Check logs for configuration errors

### Debug Commands

```bash
# Check pod status
kubectl get pods -n dev

# View pod logs
kubectl logs -n dev deployment/soup-and-nutz-dev

# Describe pod for events
kubectl describe pod -n dev <pod-name>

# Check service endpoints
kubectl get endpoints -n dev
```

## Production Considerations

### Security

- Use strong passwords for databases
- Enable Redis authentication
- Use TLS for ingress
- Implement proper RBAC
- Use secrets for sensitive data

### Performance

- Configure resource limits appropriately
- Enable horizontal pod autoscaling
- Use persistent volumes for databases
- Configure proper connection pooling

### Backup

Enable automated backups:

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 30
```

## Customization

### Adding Custom Values

Create a custom values file:

```yaml
# custom-values.yaml
image:
  repository: your-registry/soup-and-nutz
  tag: "latest"

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
```

Deploy with custom values:

```bash
helm install soup-and-nutz ./helm/soup-and-nutz \
  -f helm/soup-and-nutz/values-prod.yaml \
  -f custom-values.yaml
```

### Extending the Chart

The Helm chart is modular and can be extended:

- Add new services in `templates/`
- Create new values files for different environments
- Add custom resource definitions
- Implement custom health checks 