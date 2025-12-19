#!/bin/bash

# Script to create Kubernetes secrets without hardcoding in YAML
# Usage: ./create-secrets.sh

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║         🔒 Kubernetes Secret Creation Script 🔒               ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace app &> /dev/null; then
    echo "📦 Creating namespace 'app'..."
    kubectl create namespace app
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Enter Secret Values"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ℹ️  Note: This Nginx app only needs APP_BANNER"
echo "ℹ️  DB_PASSWORD and API_KEY are optional (commented out)"
echo ""

# Read secrets from user
read -p "APP_BANNER (e.g., GlobalLogic): " APP_BANNER
echo ""

# Optional: Uncomment if you need database credentials
# read -sp "DB_PASSWORD (hidden): " DB_PASSWORD
# echo ""
# read -sp "API_KEY (hidden): " API_KEY
# echo ""
# echo ""

# Validate inputs
if [ -z "$APP_BANNER" ]; then
    echo "❌ Error: APP_BANNER is required!"
    exit 1
fi

# Delete existing secret if it exists
echo "🗑️  Deleting old secret (if exists)..."
kubectl delete secret app-secrets -n app --ignore-not-found=true

# Create new secret
echo "✅ Creating new secret..."
kubectl create secret generic app-secrets \
    --namespace=app \
    --from-literal=APP_BANNER="$APP_BANNER"
    # Add more secrets as needed:
    # --from-literal=DB_PASSWORD="$DB_PASSWORD" \
    # --from-literal=API_KEY="$API_KEY"

# Verify secret creation
echo ""
echo "✅ Secret created successfully!"
echo ""
kubectl get secret app-secrets -n app
echo ""

# Show secret keys (not values)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Secret contains the following keys:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl describe secret app-secrets -n app | grep -E "APP_BANNER|DB_PASSWORD|API_KEY"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  ✅ Secret 'app-secrets' created in namespace 'app'           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Next steps:"
echo "   1. Deploy your application: kubectl apply -f manifests/deployment.yaml"
echo "   2. Verify secrets in pod: kubectl exec -n app deployment/nginx-deployment -- env"
echo ""

