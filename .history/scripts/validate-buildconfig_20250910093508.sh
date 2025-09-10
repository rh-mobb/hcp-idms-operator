#!/bin/bash

# Validate BuildConfig deployment files

set -e

echo "Validating BuildConfig deployment files..."

# Check if we're in an OpenShift cluster
if ! oc get crd buildconfigs.build.openshift.io >/dev/null 2>&1; then
    echo "Warning: This script requires an OpenShift cluster with BuildConfig support"
    echo "Skipping OpenShift-specific validation"
fi

# Validate YAML files
echo "Validating YAML files..."

for file in config/openshift/*.yaml; do
    if [ -f "$file" ]; then
        echo "Validating $file..."
        oc apply --dry-run=client -f "$file"
    fi
done

# Validate RBAC files
echo "Validating RBAC files..."
oc apply --dry-run=client -f config/rbac/

# Validate Dockerfile
echo "Validating Dockerfile.buildconfig..."
if [ -f "Dockerfile.buildconfig" ]; then
    echo "Dockerfile.buildconfig exists and is ready for BuildConfig"
else
    echo "Error: Dockerfile.buildconfig not found"
    exit 1
fi

# Check if manager binary can be built
echo "Checking if manager binary can be built..."
if make manager; then
    echo "Manager binary builds successfully"
else
    echo "Error: Failed to build manager binary"
    exit 1
fi

echo "All BuildConfig files are valid!"
echo ""
echo "Ready to deploy with: make deploy-buildconfig"
