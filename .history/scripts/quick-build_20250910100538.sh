#!/bin/bash

# Quick build script - upload only the binary file

set -e

echo "Quick build: uploading only the binary file..."

# Build the operator binary first
echo "Building operator binary for Linux AMD64..."
GOOS=linux GOARCH=amd64 make manager

# Verify binary exists
if [ ! -f "bin/manager" ]; then
    echo "Error: Binary not found at bin/manager"
    exit 1
fi

# Start the build with only the binary file
echo "Starting build with binary file only..."
oc start-build hcp-idms-operator --from-file=bin/manager --follow

echo "Build complete!"
echo ""
echo "To check build status:"
echo "  oc get builds -n openshift-hcp-idms-operator"
echo "  oc logs -f build/hcp-idms-operator-<number>"
