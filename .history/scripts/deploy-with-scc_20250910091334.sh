#!/bin/bash

# Deploy the hcp-idms-operator with proper security context constraints

set -e

echo "Deploying hcp-idms-operator with SecurityContextConstraints..."

# Apply RBAC first
echo "Applying RBAC..."
kubectl apply -f config/rbac/

# Apply SecurityContextConstraints
echo "Applying SecurityContextConstraints..."
kubectl apply -f config/rbac/security_context_constraints.yaml

# Apply CRDs
echo "Applying CRDs..."
kubectl apply -f config/crd/bases/

# Apply DaemonSet
echo "Applying DaemonSet..."
kubectl apply -f config/manager/daemonset.yaml

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  kubectl get pods -n system -l app=hcp-idms-operator"
echo "  kubectl get scc hcp-idms-operator"
echo "  kubectl describe scc hcp-idms-operator"
