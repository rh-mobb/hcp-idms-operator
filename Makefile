# Image URL to use all building/pushing image targets
IMG ?= ghcr.io/rh-mobb/hcp-idms-operator:latest
# Produce CRDs that work back to Kubernetes 1.11 (no version conversion)
CRD_OPTIONS ?= "crd:crdVersions=v1"

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed in recipes with
# .SHELLFLAGS = -o pipefail -c in some cases
SHELL = /usr/bin/env bash -o pipefail
# You can set VERSION_SCHEMA to a different value to override the default
VERSION_SCHEMA = v1alpha1

all: manager

# Run tests
test: generate fmt vet manifests
	go test ./... -coverprofile cover.out

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager cmd/manager/main.go

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet manifests
	go run ./cmd/manager/main.go

# Install CRDs into a cluster
install: manifests kustomize
	$(KUSTOMIZE) build config/crd | oc apply -f -

# Uninstall CRDs from a cluster
uninstall: manifests kustomize
	$(KUSTOMIZE) build config/crd | oc delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: manifests kustomize
	cd config/manager && $(KUSTOMIZE) edit set image controller=${IMG}
	$(KUSTOMIZE) build config/default | oc apply -f -

# Deploy DaemonSet in the configured Kubernetes cluster in ~/.kube/config
deploy-daemonset: manifests kustomize
	oc apply -f config/rbac/service_account.yaml
	oc apply -f config/rbac/role.yaml
	oc apply -f config/rbac/role_binding.yaml
	oc apply -f config/rbac/security_context_constraints.yaml
	oc apply -f config/manager/daemonset.yaml

# Deploy DaemonSet with SCC for OpenShift
deploy-daemonset-openshift: manifests kustomize
	./scripts/deploy-with-scc.sh

# Deploy using BuildConfig for local development on OpenShift
deploy-buildconfig: manifests

	./scripts/deploy-buildconfig.sh

# Clean up BuildConfig deployment
cleanup-buildconfig:
	./scripts/cleanup-buildconfig.sh

# UnDeploy controller from the configured Kubernetes cluster in ~/.kube/config
undeploy: kustomize
	$(KUSTOMIZE) build config/default | oc delete -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests: controller-gen
	$(CONTROLLER_GEN) $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases

# Run go fmt against code
fmt:
	go fmt ./...

# Run go vet against code
vet:
	go vet ./...

# Generate code
generate: controller-gen
	$(CONTROLLER_GEN) object paths="./..."

# Download controller-gen locally if necessary
CONTROLLER_GEN = $(shell pwd)/bin/controller-gen
controller-gen:
	$(call go-get-tool,$(CONTROLLER_GEN),sigs.k8s.io/controller-tools/cmd/controller-gen@v0.19.0)

# Download kustomize locally if necessary
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize:
	$(call go-get-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v5@latest)

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef

# Build the podman image
podman-build: #test
	podman build -t ${IMG} .

# Build the podman image for x86 architecture
podman-build-x86: #test
	podman build --platform linux/amd64 -t ${IMG} .

# Push the podman image
podman-push:
	podman push ${IMG}

# Push the x86 podman image
podman-push-x86:
	podman push ${IMG}

# Run CI tests locally
ci: test fmt vet manifests
	@echo "Running CI tests locally..."

# Run comprehensive test suite
test-ci: test fmt vet manifests build
	@echo "Running comprehensive test suite..."
	@echo "✓ Unit tests passed"
	@echo "✓ Formatting check passed"
	@echo "✓ Vet check passed"
	@echo "✓ Manifests generated"
	@echo "✓ Binary built successfully"
	@echo "All CI tests passed!"


.PHONY: all test manager run install uninstall deploy deploy-daemonset deploy-daemonset-openshift deploy-buildconfig cleanup-buildconfig undeploy manifests fmt vet generate controller-gen kustomize podman-build podman-build-x86 podman-push podman-push-x86 ci test-ci