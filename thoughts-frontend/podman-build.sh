#!/usr/bin/env bash
# Build the thoughts-frontend image using podman
# Two-step approach: 1) Build Next.js app locally, 2) Package in container
# Note: Backend URL is configured at runtime via API_BACKEND_URL env var, not at build time

set -e

echo "Step 1: Building Next.js app locally..."
npm run build

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
