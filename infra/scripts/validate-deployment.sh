#!/bin/bash

# Validate Kubernetes Deployment
# This script checks if the application is deployed successfully

set -e

NAMESPACE="${NAMESPACE:-app}"
DEPLOYMENT="${DEPLOYMENT:-nginx-deployment}"
SERVICE="${SERVICE:-nginx-service}"

echo "========================================="
echo "Validating Kubernetes Deployment"
echo "========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check cluster connection
echo "Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to cluster"
    echo "Run: aws eks update-kubeconfig --name <cluster-name> --region <region>"
    exit 1
fi

echo "Connected to cluster ✓"

# Check namespace
echo ""
echo "Checking namespace: ${NAMESPACE}"
if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    echo "Namespace exists ✓"
else
    echo "Error: Namespace ${NAMESPACE} not found"
    exit 1
fi

# Check deployment
echo ""
echo "Checking deployment: ${DEPLOYMENT}"
if kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" &> /dev/null; then
    echo "Deployment exists ✓"
    
    # Check deployment status
    READY=$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}')
    
    echo "Ready replicas: ${READY}/${DESIRED}"
    
    if [ "$READY" == "$DESIRED" ]; then
        echo "All replicas are ready ✓"
    else
        echo "Warning: Not all replicas are ready"
    fi
else
    echo "Error: Deployment ${DEPLOYMENT} not found"
    exit 1
fi

# Check pods
echo ""
echo "Checking pods..."
kubectl get pods -n "${NAMESPACE}" -l app=nginx

POD_STATUS=$(kubectl get pods -n "${NAMESPACE}" -l app=nginx -o jsonpath='{.items[*].status.phase}')
if echo "$POD_STATUS" | grep -q "Running"; then
    echo "Pods are running ✓"
else
    echo "Warning: Some pods are not running"
fi

# Check service
echo ""
echo "Checking service: ${SERVICE}"
if kubectl get service "${SERVICE}" -n "${NAMESPACE}" &> /dev/null; then
    echo "Service exists ✓"
    
    # Get LoadBalancer URL
    LB_HOSTNAME=$(kubectl get service "${SERVICE}" -n "${NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -n "$LB_HOSTNAME" ]; then
        echo ""
        echo "========================================="
        echo "Application is accessible at:"
        echo "http://${LB_HOSTNAME}"
        echo "========================================="
        
        # Test connectivity
        echo ""
        echo "Testing connectivity..."
        if curl -s -o /dev/null -w "%{http_code}" "http://${LB_HOSTNAME}" | grep -q "200"; then
            echo "Application is responding ✓"
        else
            echo "Warning: Application not responding yet (may take a few minutes)"
        fi
    else
        echo "Warning: LoadBalancer hostname not available yet"
    fi
else
    echo "Error: Service ${SERVICE} not found"
    exit 1
fi

echo ""
echo "========================================="
echo "Validation complete!"
echo "========================================="

