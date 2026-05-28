#!/usr/bin/env bash
# Build the thoughts-frontend image using podman
# Two-step approach: 1) Build Next.js app locally, 2) Package in container

set -e

# Set default environment variables for the build
NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL:-http://localhost:8080}

echo "Step 1: Building Next.js app locally..."
echo "API Base URL: ${NEXT_PUBLIC_API_BASE_URL}"
NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL}" npm run build

echo ""
echo "Step 2: Building container image..."
podman build \
  --platform linux/amd64 \
  -t thoughtsapp/frontend:latest \
  -f ContainerFile.runtime \
  .

# Tag the image for container registry
podman tag thoughtsapp/frontend:latest quay.io/redhat_na_ssa/thoughtsapp-frontend:latest

echo ""
echo "Build complete!"
podman push quay.io/redhat_na_ssa/thoughtsapp-frontend:latest

# Usage notes:
# Set environment variables before running:
# export NEXT_PUBLIC_API_BASE_URL=https://your-backend-url
# ./podman-build.sh
