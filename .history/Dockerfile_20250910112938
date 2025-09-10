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
FROM golang:1.24 as builder

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
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o manager cmd/manager/main.go

# Use UBI minimal as base image to package the manager binary
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Install necessary packages
RUN microdnf install -y ca-certificates && microdnf clean all

# Create non-root user
RUN useradd -u 65532 -g 65532 -s /bin/false -m manager

WORKDIR /

# Copy the binary from builder stage
COPY --from=builder /workspace/manager /manager

# Change ownership
RUN chown 65532:65532 /manager

# Switch to non-root user
USER 65532:65532

# Expose ports
EXPOSE 8080 8081

ENTRYPOINT ["/manager"]
