#!/usr/bin/env bash
# Build the thoughts-frontend image using podman

set -e

# Set default environment variables for the build
NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL:-http://localhost:8080}

echo "Building thoughts-frontend..."
echo "API Base URL: ${NEXT_PUBLIC_API_BASE_URL}"

# Build the image
podman build \
  --build-arg NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL}" \
  -t thoughtsapp/frontend:latest \
  -f ContainerFile \
  .

# Tag the image for container registry
podman tag thoughtsapp/frontend:latest quay.io/redhat_na_ssa/thoughtsapp-frontend:latest

echo "Build complete. To push to registry, run:"
echo "  podman push quay.io/redhat_na_ssa/thoughtsapp-frontend:latest"

# Uncomment to automatically push:
podman push quay.io/redhat_na_ssa/thoughtsapp-frontend:latest

# Usage notes:
# Set environment variables before running:
# export NEXT_PUBLIC_API_BASE_URL=https://your-backend-url
# ./podman-build.sh
