#!/usr/bin/env bash
# Build the Streamlit image using podman
podman build -t thoughtsapp/python-report:latest -f thoughtsapp-rh26/python-report/Dockerfile .

# Tag the image for your OpenShift registry (replace <registry> and <project> with your values)
podman tag thoughtsapp/python-report:latest quay.io/redhat_na_ssa/thoughtsapp-python-report:latest

# Push the image to the registry
podman push quay.io/redhat_na_ssa/thoughtsapp-python-report:latest

# Note: Uncomment and replace placeholders above before running.
