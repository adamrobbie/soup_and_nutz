# Soup and Nutz Helm Chart

A Helm chart for deploying the Soup and Nutz personal finance management application on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Ingress controller (e.g., nginx-ingress) for external access
- Storage class for persistent volumes

## Quick Start

### 1. Add the Bitnami repository
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Install the chart
```bash
# Development
./scripts/deploy.sh dev install

# Production
./scripts/deploy.sh prod install
```

### 3. Access the application
```bash
# Get the ingress URL
kubectl get ingress -n dev
```

## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of application replicas | `2` |
| `image.repository` | Docker image repository | `adamrobbie/soup-and-nutz` |
| `image.tag` | Docker image tag | `0.2.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `4000` |
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `resources.limits.cpu` | CPU limit | `1000m` |
| `resources.limits.memory` | Memory limit | `1Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `redis.enabled` | Enable Redis | `true` |

## Environment-Specific Values

### Development (`values-dev.yaml`)
- Single replica
- Latest image tag
- No persistence for databases
- Ingress enabled for local development

### Production (`values-prod.yaml`)
- Multiple replicas with autoscaling
- Specific image tag
- Persistent storage
- TLS/SSL enabled
- Monitoring enabled

## Secrets Management

The application requires the following secrets:

```bash
# Create secrets manually
kubectl create secret generic soup-and-nutz-secret \
  --from-literal=secret-key-base="your-secret-key-base" \
  --from-literal=database-url="postgresql://user:pass@host:5432/db"
```

Or use external secrets management tools like:
- External Secrets Operator
- Sealed Secrets
- HashiCorp Vault

## Database Migrations

Database migrations run automatically before each deployment using Helm hooks. The migration job:
- Runs before install/upgrade
- Uses the same image as the application
- Executes `mix ecto.migrate`

## Monitoring

### Prometheus ServiceMonitor
Enable monitoring in production:
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

### Health Checks
The application includes:
- Liveness probe: `/health`
- Readiness probe: `/health`

## Backup

Enable automated backups in production:
```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM
  retention: 30  # Keep 30 days
```

## Scaling

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
kubectl scale deployment soup-and-nutz --replicas=5 -n prod
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n dev -l app.kubernetes.io/instance=soup-and-nutz-dev
```

### View Logs
```bash
kubectl logs -n dev -l app.kubernetes.io/instance=soup-and-nutz-dev
```

### Check Events
```bash
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Debug Migration Job
```bash
kubectl logs -n dev job/soup-and-nutz-dev-migration
```

## Upgrading

### Upgrade the Release
```bash
./scripts/deploy.sh prod upgrade
```

### Rollback
```bash
helm rollback soup-and-nutz-prod 1 -n prod
```

## Uninstalling

```bash
helm uninstall soup-and-nutz-dev -n dev
kubectl delete namespace dev
```

## Contributing

1. Update the chart version in `Chart.yaml`
2. Test with `helm lint helm/soup-and-nutz`
3. Test template rendering: `helm template test helm/soup-and-nutz`
4. Update this README with any new parameters 