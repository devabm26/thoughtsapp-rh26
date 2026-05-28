#!/usr/bin/env bash
# Build the thoughts-backend image using podman

set -e

echo "Building thoughts-backend..."

# Build the image
podman build \
  -t thoughtsapp/backend:latest \
  -f ContainerFile \
  .

# Tag the image for container registry
podman tag thoughtsapp/backend:latest quay.io/redhat_na_ssa/thoughtsapp-backend:latest

echo "Build complete. To push to registry, run:"
echo "  podman push quay.io/redhat_na_ssa/thoughtsapp-backend:latest"

# Uncomment to automatically push:
podman push quay.io/redhat_na_ssa/thoughtsapp-backend:latest
