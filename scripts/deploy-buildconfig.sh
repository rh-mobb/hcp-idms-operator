#!/bin/bash

# Deploy the hcp-idms-operator using BuildConfig for local development

set -e

echo "Deploying hcp-idms-operator using BuildConfig..."

# Check if we're in an OpenShift cluster
if ! oc whoami >/dev/null 2>&1; then
    echo "Error: This script requires an OpenShift cluster"
    echo "Please ensure you're connected to an OpenShift cluster"
    exit 1
fi

# Create namespace if it doesn't exist
oc create namespace openshift-hcp-idms-operator --dry-run=client -o yaml | oc apply -f -


# Check if we're in the right namespace
CURRENT_NS=$(oc config view --minify -o jsonpath='{..namespace}')
if [ "$CURRENT_NS" != "openshift-hcp-idms-operator" ]; then
    echo "Switching to openshift-hcp-idms-operator namespace..."
    oc config set-context --current --namespace=openshift-hcp-idms-operator
fi

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
oc apply -f config/openshift/buildconfig.yaml

# Build the binary first for x86 architecture
echo "Building operator binary for x86 architecture..."
GOOS=linux GOARCH=amd64 make manager

# Create temporary build directory
echo "Preparing build context..."
mkdir -p build-temp
cp bin/manager build-temp/manager
cp Dockerfile.binary build-temp/Dockerfile

# Start the build with binary and Dockerfile
echo "Starting build from pre-built binary..."
oc start-build hcp-idms-operator --from-dir=build-temp --follow

# Wait for the build to complete
echo "Waiting for build to complete..."
BUILD_NAME=$(oc get builds -o name | grep hcp-idms-operator | tail -1 | cut -d'/' -f2)
oc wait --for=condition=complete build/$BUILD_NAME

# Apply the DaemonSet with BuildConfig image
echo "Applying DaemonSet with BuildConfig image..."
oc apply -f config/openshift/daemonset-buildconfig.yaml

echo "Deployment complete!"
echo ""
echo "To verify the deployment:"
echo "  oc get pods -n openshift-hcp-idms-operator -l app=hcp-idms-operator"
echo "  oc get build -n openshift-hcp-idms-operator"
echo "  oc get imagestream -n openshift-hcp-idms-operator"
echo "  oc logs -f build/\$BUILD_NAME"
echo ""
echo "To rebuild and redeploy:"
echo "GOOS=linux GOARCH=amd64 make manager && mkdir -p build-temp && cp bin/manager build-temp/manager && cp Dockerfile.binary build-temp/Dockerfile && oc start-build hcp-idms-operator --from-dir=build-temp --follow && rm -rf build-temp"

# Clean up temporary build directory
echo "Cleaning up temporary build directory..."
rm -rf build-temp

echo "Build complete!"
