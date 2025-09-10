#!/bin/bash

# Clean up the hcp-idms-operator BuildConfig deployment

set -e

echo "Cleaning up hcp-idms-operator BuildConfig deployment..."

# Check if we're in an OpenShift cluster
if ! kubectl get crd buildconfigs.build.openshift.io >/dev/null 2>&1; then
    echo "Error: This script requires an OpenShift cluster with BuildConfig support"
    echo "Please ensure you're connected to an OpenShift cluster"
    exit 1
fi

# Check if we're in the right namespace
CURRENT_NS=$(kubectl config view --minify -o jsonpath='{..namespace}')
if [ "$CURRENT_NS" != "openshift-hcp-idms-operator" ]; then
    echo "Switching to openshift-hcp-idms-operator namespace..."
    kubectl config set-context --current --namespace=openshift-hcp-idms-operator
fi

# Delete DaemonSet
echo "Deleting DaemonSet..."
kubectl delete -f config/openshift/daemonset-buildconfig.yaml --ignore-not-found=true

# Delete BuildConfig
echo "Deleting BuildConfig..."
kubectl delete -f config/openshift/buildconfig.yaml --ignore-not-found=true

# Delete ImageStream
echo "Deleting ImageStream..."
kubectl delete -f config/openshift/imagestream.yaml --ignore-not-found=true

# Delete SecurityContextConstraints
echo "Deleting SecurityContextConstraints..."
kubectl delete -f config/rbac/security_context_constraints.yaml --ignore-not-found=true

# Delete RBAC
echo "Deleting RBAC..."
kubectl delete -f config/rbac/role_binding.yaml --ignore-not-found=true
kubectl delete -f config/rbac/role.yaml --ignore-not-found=true
kubectl delete -f config/rbac/service_account.yaml --ignore-not-found=true

echo "Cleanup complete!"
echo ""
echo "To verify cleanup:"
echo "  kubectl get pods -n openshift-hcp-idms-operator -l app=hcp-idms-operator"
echo "  kubectl get build -n openshift-hcp-idms-operator"
echo "  kubectl get imagestream -n openshift-hcp-idms-operator"
echo "  kubectl get scc hcp-idms-operator"
