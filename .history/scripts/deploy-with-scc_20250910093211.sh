#!/bin/bash

# Deploy the hcp-idms-operator with proper security context constraints

set -e

echo "Deploying hcp-idms-operator with SecurityContextConstraints..."

# Create namespace if it doesn't exist
oc create namespace openshift-hcp-idms-operator --dry-run=client -o yaml | oc apply -f -

# Apply RBAC first
echo "Applying RBAC..."
oc apply -f config/rbac/

# Apply SecurityContextConstraints
echo "Applying SecurityContextConstraints..."
oc apply -f config/rbac/security_context_constraints.yaml

# No need to Apply CRDs, they should already be present in OpenShift
# echo "Applying CRDs..."
# oc apply -f config/crd/bases/

# Apply DaemonSet
echo "Applying DaemonSet..."
oc apply -f config/manager/daemonset.yaml

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  oc get pods -n openshift-hcp-idms-operator -l app=hcp-idms-operator"
echo "  oc get scc hcp-idms-operator"
echo "  oc describe scc hcp-idms-operator"
