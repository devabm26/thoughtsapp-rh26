#!/usr/bin/env bash
# Build the thoughts-evaluation image using podman

set -e

echo "Building thoughts-evaluation..."

# Build the image
podman build \
  -t thoughtsapp/evaluation:latest \
  -f ContainerFile \
  .

# Tag the image for container registry
podman tag thoughtsapp/evaluation:latest quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest

echo "Build complete. To push to registry, run:"
echo "  podman push quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest"

# Uncomment to automatically push:
# podman push quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest
