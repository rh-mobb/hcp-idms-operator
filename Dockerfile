# Copyright 2024 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Build the manager binary
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS builder

LABEL org.opencontainers.image.source=https://github.com/rh-mobb/hcp-idms-operator

# Install Go
RUN microdnf install -y go-toolset && microdnf clean all

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/ cmd/
COPY api/ api/
COPY internal/ internal/

# Build
RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o manager cmd/manager/main.go

# Use UBI minimal as base image to package the manager binary
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Install necessary packages
RUN microdnf install -y ca-certificates systemd procps-ng && microdnf clean all

WORKDIR /

# Copy the binary from builder stage
COPY --from=builder /workspace/manager /manager

# Make binary executable
RUN chmod +x /manager

# Expose ports
EXPOSE 8080 8081

ENTRYPOINT ["/manager"]
