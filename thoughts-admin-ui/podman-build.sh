#!/usr/bin/env bash
# Build the thoughts-admin-ui image using podman
# Two-step approach: 1) Build Vite app locally, 2) Package in container

set -e

# Set default environment variables for the build
VITE_API_BASE_URL=${VITE_API_BASE_URL:-http://localhost:8080}
VITE_EVALUATION_API_BASE_URL=${VITE_EVALUATION_API_BASE_URL:-http://localhost:8088}

echo "Step 1: Building Vite app locally..."
echo "API Base URL: ${VITE_API_BASE_URL}"
echo "Evaluation API Base URL: ${VITE_EVALUATION_API_BASE_URL}"
VITE_API_BASE_URL="${VITE_API_BASE_URL}" \
VITE_EVALUATION_API_BASE_URL="${VITE_EVALUATION_API_BASE_URL}" \
VITE_ADMIN_USER="${VITE_ADMIN_USER}" \
VITE_ADMIN_PASS="${VITE_ADMIN_PASS}" \
npm run build

echo ""
echo "Step 2: Building container image..."
podman build \
  --platform linux/amd64 \
  -t thoughtsapp/admin-ui:latest \
  -f ContainerFile.runtime \
  .

# Tag the image for container registry
podman tag thoughtsapp/admin-ui:latest quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest

echo ""
echo "Build complete!"
podman push quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest

# Usage notes:
# Set environment variables before running:
# export VITE_API_BASE_URL=https://your-backend-url
# export VITE_EVALUATION_API_BASE_URL=https://your-evaluation-url
# export VITE_ADMIN_USER=admin
# export VITE_ADMIN_PASS=your-password
# ./podman-build.sh
