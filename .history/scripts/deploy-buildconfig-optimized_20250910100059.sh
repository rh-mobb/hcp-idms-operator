#!/bin/bash

# Deploy the hcp-idms-operator using optimized BuildConfig for binary-only upload

set -e

echo "Deploying hcp-idms-operator using optimized BuildConfig..."

# Check if we're in an OpenShift cluster
if ! oc whoami >/dev/null 2>&1; then
    echo "Error: This script requires an OpenShift cluster"
    echo "Please ensure you're connected to an OpenShift cluster"
    exit 1
fi

# Check if we're in the right namespace
CURRENT_NS=$(oc config view --minify -o jsonpath='{..namespace}')
if [ "$CURRENT_NS" != "openshift-hcp-idms-operator" ]; then
    echo "Switching to openshift-hcp-idms-operator namespace..."
    oc config set-context --current --namespace=openshift-hcp-idms-operator
fi

# Build the operator binary first
echo "Building operator binary for Linux AMD64..."
GOOS=linux GOARCH=amd64 make manager

# Verify binary exists
if [ ! -f "bin/manager" ]; then
    echo "Error: Binary not found at bin/manager"
    exit 1
fi

# Create minimal build context
echo "Creating minimal build context..."
BUILD_DIR=$(mktemp -d)
cp bin/manager "$BUILD_DIR/manager"
cp Dockerfile.binary "$BUILD_DIR/Dockerfile"

# Create namespace if it doesn't exist
oc create namespace openshift-hcp-idms-operator --dry-run=client -o yaml | oc apply -f -

# Apply RBAC first
echo "Applying RBAC..."
oc apply -f config/rbac/service_account.yaml
oc apply -f config/rbac/role.yaml
oc apply -f config/rbac/role_binding.yaml

# Apply SecurityContextConstraints
echo "Applying SecurityContextConstraints..."
oc apply -f config/rbac/security_context_constraints.yaml

# Apply ImageStream
echo "Creating ImageStream..."
oc apply -f config/openshift/imagestream.yaml

# Apply BuildConfig
echo "Creating BuildConfig..."
oc apply -f config/openshift/buildconfig-optimized.yaml

# Start the build with minimal context
echo "Starting build from minimal context..."
cd "$BUILD_DIR"
oc start-build hcp-idms-operator-optimized --from-dir=. --follow

# Wait for the build to complete
echo "Waiting for build to complete..."
BUILD_NAME=$(oc get builds -o name | grep hcp-idms-operator-optimized | tail -1 | cut -d'/' -f2)
oc wait --for=condition=complete build/$BUILD_NAME --timeout=300s

# Apply the DaemonSet with BuildConfig image
echo "Applying DaemonSet with BuildConfig image..."
oc apply -f config/openshift/daemonset-buildconfig.yaml

# Clean up build directory
echo "Cleaning up build context..."
cd - > /dev/null
rm -rf "$BUILD_DIR"

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  oc get pods -n openshift-hcp-idms-operator -l app=hcp-idms-operator"
echo "  oc get build -n openshift-hcp-idms-operator-optimized"
echo "  oc get imagestream -n openshift-hcp-idms-operator"
echo "  oc logs -f build/\$BUILD_NAME"
echo ""
echo "To rebuild and redeploy:"
echo "  GOOS=linux GOARCH=amd64 make manager && ./scripts/deploy-buildconfig-optimized.sh"
