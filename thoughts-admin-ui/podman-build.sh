#!/usr/bin/env bash
# Build the thoughts-admin-ui image using podman

# Set default environment variables for the build
# These can be overridden by setting them before running this script
VITE_API_BASE_URL=${VITE_API_BASE_URL:-http://localhost:8080}
VITE_EVALUATION_API_BASE_URL=${VITE_EVALUATION_API_BASE_URL:-http://localhost:8088}

# Build the image
podman build \
  --build-arg VITE_API_BASE_URL="${VITE_API_BASE_URL}" \
  --build-arg VITE_EVALUATION_API_BASE_URL="${VITE_EVALUATION_API_BASE_URL}" \
  --build-arg VITE_ADMIN_USER="${VITE_ADMIN_USER}" \
  --build-arg VITE_ADMIN_PASS="${VITE_ADMIN_PASS}" \
  -t thoughtsapp/admin-ui:latest \
  -f ContainerFile \
  .

# Tag the image for your container registry (replace with your values)
podman tag thoughtsapp/admin-ui:latest quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest

# Push the image to the registry
podman push quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest

# Note: Set environment variables before running:
# export VITE_API_BASE_URL=https://your-backend-url
# export VITE_EVALUATION_API_BASE_URL=https://your-evaluation-url
# export VITE_ADMIN_USER=admin
# export VITE_ADMIN_PASS=your-password
