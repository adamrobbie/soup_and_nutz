# Kubernetes Deployment Guide

This guide covers deploying the Soup and Nutz application to Kubernetes using Helm charts.

## Prerequisites

### Required Tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes command-line tool
- [Helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- [Docker](https://docs.docker.com/get-docker/) - Container runtime

### Cluster Requirements
- Kubernetes 1.19 or later
- Ingress controller (nginx-ingress recommended)
- Storage class for persistent volumes
- At least 2 CPU cores and 4GB RAM available

## Quick Start

### 1. Build and Push Docker Image

```bash
# Build the image
docker build -t adamrobbie/soup-and-nutz:0.2.0 .

# Push to registry (replace with your registry)
docker push adamrobbie/soup-and-nutz:0.2.0
```

### 2. Deploy to Development

```bash
# Install to development environment
./scripts/deploy.sh dev install
```

### 3. Access the Application

```bash
# Get the ingress URL
kubectl get ingress -n dev

# Port forward for local access
kubectl port-forward -n dev svc/soup-and-nutz-dev 4000:80
```

## Environment Configurations

### Development Environment
- **Purpose**: Local development and testing
- **Resources**: Minimal (1 replica, 256Mi RAM)
- **Storage**: Ephemeral (no persistence)
- **Access**: Ingress enabled for local development

### Production Environment
- **Purpose**: Live production deployment
- **Resources**: Scaled (3+ replicas, 1Gi RAM)
- **Storage**: Persistent volumes
- **Access**: TLS/SSL enabled ingress
- **Monitoring**: Prometheus metrics enabled

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Application   │    │   PostgreSQL    │
│   Controller    │───▶│   (Phoenix)     │───▶│   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Redis       │
                       │   (Caching)     │
                       └─────────────────┘
```

## Configuration Management

### Secrets
The application requires these secrets:
- `secret-key-base`: Phoenix secret key base
- `database-url`: PostgreSQL connection string

### Environment Variables
- `MIX_ENV`: Set to "prod"
- `PHX_HOST`: Application host
- `PHX_PORT`: Application port
- `DATABASE_URL`: Database connection
- `SECRET_KEY_BASE`: Phoenix secret

## Database Management

### Automatic Migrations
Database migrations run automatically before each deployment:
- Uses Helm hooks (`pre-install`, `pre-upgrade`)
- Runs `mix ecto.migrate`
- Ensures database schema is up to date

### Backup Strategy
For production environments:
- Automated daily backups
- 30-day retention policy
- Point-in-time recovery capability

## Monitoring and Observability

### Health Checks
- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/health` endpoint
- **Startup Probe**: Application startup time

### Metrics
- Prometheus ServiceMonitor (production)
- Custom application metrics
- Resource utilization tracking

### Logging
- Structured JSON logging
- Centralized log aggregation
- Log retention policies

## Scaling Strategies

### Horizontal Pod Autoscaler
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Manual Scaling
```bash
# Scale to 5 replicas
kubectl scale deployment soup-and-nutz-prod --replicas=5 -n prod
```

## Security Considerations

### Network Security
- Pod-to-pod communication via services
- Ingress with TLS termination
- Network policies for traffic control

### Secrets Management
- Kubernetes secrets for sensitive data
- External secrets operators for advanced use cases
- Regular secret rotation

### RBAC
- Service accounts with minimal permissions
- Role-based access control
- Namespace isolation

## Troubleshooting

### Common Issues

#### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n dev

# View pod events
kubectl describe pod <pod-name> -n dev

# Check logs
kubectl logs <pod-name> -n dev
```

#### Database Connection Issues
```bash
# Check database pod
kubectl get pods -n dev -l app.kubernetes.io/name=postgresql

# Test database connectivity
kubectl exec -it <app-pod> -n dev -- mix ecto.dump
```

#### Migration Failures
```bash
# Check migration job
kubectl get jobs -n dev

# View migration logs
kubectl logs job/soup-and-nutz-dev-migration -n dev
```

### Debug Commands

```bash
# Get all resources in namespace
kubectl get all -n dev

# Check events
kubectl get events -n dev --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward -n dev svc/soup-and-nutz-dev 4000:80

# Execute commands in pod
kubectl exec -it <pod-name> -n dev -- /bin/sh
```

## Performance Optimization

### Resource Limits
- CPU: 1000m (1 core) limit, 500m request
- Memory: 1Gi limit, 512Mi request
- Adjust based on actual usage

### Caching Strategy
- Redis for session storage
- Application-level caching
- CDN for static assets

### Database Optimization
- Connection pooling
- Query optimization
- Index management

## Backup and Recovery

### Backup Strategy
- Automated daily backups
- Point-in-time recovery
- Cross-region replication

### Disaster Recovery
- Multi-zone deployment
- Backup verification
- Recovery testing procedures

## CI/CD Integration

### GitHub Actions
The repository includes GitHub Actions workflows for:
- Automated testing
- Docker image building
- Helm chart validation
- Deployment automation

### Deployment Pipeline
1. Code commit triggers CI
2. Tests run automatically
3. Docker image built and pushed
4. Helm chart updated
5. Deployment to staging/production

## Cost Optimization

### Resource Management
- Right-size resource requests/limits
- Use spot instances where appropriate
- Implement auto-scaling policies

### Storage Optimization
- Use appropriate storage classes
- Implement data lifecycle policies
- Regular cleanup of unused resources

## Best Practices

### Development
- Use local Kubernetes (minikube, kind) for development
- Implement proper health checks
- Use resource limits in all environments

### Production
- Implement proper monitoring and alerting
- Use blue-green deployments for zero downtime
- Regular security updates and patches
- Comprehensive backup and recovery testing

### Security
- Regular security audits
- Implement network policies
- Use secrets management
- Regular dependency updates

## Support and Maintenance

### Regular Maintenance
- Monthly security updates
- Quarterly performance reviews
- Annual disaster recovery testing

### Monitoring
- 24/7 application monitoring
- Automated alerting
- Performance dashboards

### Documentation
- Keep deployment guides updated
- Document troubleshooting procedures
- Maintain runbooks for common issues 