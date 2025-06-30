#!/bin/bash

# Deployment script for Soup and Nutz
# Usage: ./scripts/deploy.sh [dev|staging|prod] [install|upgrade]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_error "Usage: $0 [dev|staging|prod] [install|upgrade]"
    exit 1
fi

ENVIRONMENT=$1
ACTION=$2
RELEASE_NAME="soup-and-nutz-${ENVIRONMENT}"
VALUES_FILE="helm/soup-and-nutz/values-${ENVIRONMENT}.yaml"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(install|upgrade)$ ]]; then
    print_error "Invalid action. Use: install or upgrade"
    exit 1
fi

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    print_error "Values file not found: $VALUES_FILE"
    exit 1
fi

print_header "Deploying Soup and Nutz to $ENVIRONMENT environment"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
print_status "Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Add required repositories
print_status "Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Update dependencies
print_status "Updating chart dependencies..."
cd helm/soup-and-nutz
helm dependency update
cd ../..

# Deploy based on action
if [ "$ACTION" = "install" ]; then
    print_status "Installing release: $RELEASE_NAME"
    helm install "$RELEASE_NAME" ./helm/soup-and-nutz \
        -f "$VALUES_FILE" \
        --namespace "$ENVIRONMENT" \
        --create-namespace \
        --wait \
        --timeout 10m
elif [ "$ACTION" = "upgrade" ]; then
    print_status "Upgrading release: $RELEASE_NAME"
    helm upgrade "$RELEASE_NAME" ./helm/soup-and-nutz \
        -f "$VALUES_FILE" \
        --namespace "$ENVIRONMENT" \
        --wait \
        --timeout 10m
fi

# Show deployment status
print_status "Deployment completed successfully!"
print_status "Release name: $RELEASE_NAME"
print_status "Namespace: $ENVIRONMENT"

# Show resources
print_status "Checking deployment status..."
kubectl get pods -n "$ENVIRONMENT" -l "app.kubernetes.io/instance=$RELEASE_NAME"

# Show services
print_status "Services:"
kubectl get svc -n "$ENVIRONMENT" -l "app.kubernetes.io/instance=$RELEASE_NAME"

# Show ingress if enabled
if grep -q "enabled: true" "$VALUES_FILE"; then
    print_status "Ingress:"
    kubectl get ingress -n "$ENVIRONMENT" -l "app.kubernetes.io/instance=$RELEASE_NAME"
fi

print_header "Deployment to $ENVIRONMENT completed successfully!"
print_status "You can check the logs with: kubectl logs -n $ENVIRONMENT -l app.kubernetes.io/instance=$RELEASE_NAME" 