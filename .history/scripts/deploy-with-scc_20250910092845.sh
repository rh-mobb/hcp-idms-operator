#!/bin/bash

# Deploy the hcp-idms-operator with proper security context constraints

set -e

echo "Deploying hcp-idms-operator with SecurityContextConstraints..."

# Create namespace if it doesn't exist
kubectl create namespace openshift-hcp-idms-operator --dry-run=client -o yaml | kubectl apply -f -

# Apply RBAC first
echo "Applying RBAC..."
kubectl apply -f config/rbac/

# Apply SecurityContextConstraints
echo "Applying SecurityContextConstraints..."
kubectl apply -f config/rbac/security_context_constraints.yaml

# No need to Apply CRDs, they should already be present in OpenShift
# echo "Applying CRDs..."
# kubectl apply -f config/crd/bases/

# Apply DaemonSet
echo "Applying DaemonSet..."
kubectl apply -f config/manager/daemonset.yaml

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  kubectl get pods -n system -l app=hcp-idms-operator"
echo "  kubectl get scc hcp-idms-operator"
echo "  kubectl describe scc hcp-idms-operator"
