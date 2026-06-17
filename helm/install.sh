#!/usr/bin/env bash
# Install script for Thoughts App Helm Chart
set -e

# Usage information
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install Thoughts App using Helm on OpenShift

OPTIONS:
    -n, --namespace NAMESPACE       Kubernetes namespace (default: thoughts-app)
    -r, --release RELEASE          Helm release name (default: thoughtsapp)
    -f, --values FILE              Custom values file
    -d, --domain DOMAIN            Cluster domain (e.g., apps.cluster.example.com)
                                   If not provided, will auto-detect from OpenShift
    -h, --help                     Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE         Override default namespace
    RELEASE_NAME      Override default release name
    VALUES_FILE       Path to custom values file
    CLUSTER_DOMAIN    Override cluster domain

EXAMPLES:
    # Install with defaults (auto-detect cluster domain)
    $0

    # Install to specific namespace with custom domain
    $0 --namespace my-app --domain apps.cluster-abc.example.com

    # Install with custom values file
    $0 --values custom-values.yaml

    # Install with all options
    $0 -n production -r thoughts-prod -f values-production.yaml -d apps.prod.example.com

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -f|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -d|--domain)
            CLUSTER_DOMAIN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set defaults from environment or use built-in defaults
NAMESPACE="${NAMESPACE:-thoughts-app}"
RELEASE_NAME="${RELEASE_NAME:-thoughtsapp}"
VALUES_FILE="${VALUES_FILE:-}"
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-}"

# Auto-detect cluster domain if not provided
if [ -z "${CLUSTER_DOMAIN}" ]; then
    echo "Auto-detecting cluster domain..."
    CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' 2>/dev/null || echo "")
    if [ -n "${CLUSTER_DOMAIN}" ]; then
        echo "Detected cluster domain: ${CLUSTER_DOMAIN}"
    else
        echo "WARNING: Could not auto-detect cluster domain"
        echo "Routes will use OpenShift default domain"
    fi
fi

echo "========================================="
echo "Thoughts App Helm Installation"
echo "========================================="
echo ""
echo "Release Name: ${RELEASE_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Cluster Domain: ${CLUSTER_DOMAIN:-auto}"
echo ""

# Check if namespace exists, create if not
if ! oc get namespace "${NAMESPACE}" &>/dev/null; then
    echo "Creating namespace: ${NAMESPACE}"
    oc create namespace "${NAMESPACE}"
else
    echo "Using existing namespace: ${NAMESPACE}"
fi

# Check if AMQ Streams operator is installed
echo ""
echo "Checking for AMQ Streams operator..."
if ! oc get csv -n openshift-operators | grep -q amq-streams; then
    echo "WARNING: AMQ Streams operator not found!"
    echo "Please install AMQ Streams operator first:"
    echo "  1. Navigate to Operators → OperatorHub in OpenShift Console"
    echo "  2. Search for 'Red Hat Integration - AMQ Streams'"
    echo "  3. Click Install and select version 2.7.0-7"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ AMQ Streams operator found"
fi

# Lint the chart
echo ""
echo "Linting Helm chart..."
helm lint thoughtsapp/

# Build Helm command arguments
HELM_ARGS=(
    --namespace "${NAMESPACE}"
)

if [ -n "${VALUES_FILE}" ]; then
    HELM_ARGS+=(--values "${VALUES_FILE}")
fi

if [ -n "${CLUSTER_DOMAIN}" ]; then
    HELM_ARGS+=(--set global.clusterDomain="${CLUSTER_DOMAIN}")
fi

HELM_ARGS+=(--wait)

# Install or upgrade
echo ""
if helm list -n "${NAMESPACE}" | grep -q "${RELEASE_NAME}"; then
    echo "Upgrading existing release: ${RELEASE_NAME}"
    helm upgrade "${RELEASE_NAME}" thoughtsapp/ "${HELM_ARGS[@]}"
else
    echo "Installing new release: ${RELEASE_NAME}"
    helm install "${RELEASE_NAME}" thoughtsapp/ "${HELM_ARGS[@]}"
fi

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Getting application URLs..."
echo ""

# Wait a bit for routes to be created
sleep 5

# Get routes
FRONTEND_ROUTE=$(oc get route thoughts-frontend -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "N/A")
ADMIN_ROUTE=$(oc get route thoughts-admin-ui -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "N/A")
BACKEND_ROUTE=$(oc get route thoughts-backend -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "N/A")
EVAL_ROUTE=$(oc get route thoughts-evaluation -n "${NAMESPACE}" -o jsonpath='{.spec.host}' 2>/dev/null || echo "N/A")

echo "Frontend:    https://${FRONTEND_ROUTE}"
echo "Admin UI:    https://${ADMIN_ROUTE}"
echo "Backend API: https://${BACKEND_ROUTE}"
echo "Evaluation:  https://${EVAL_ROUTE}"
echo ""

echo "Next steps:"
echo "  1. Wait for all pods to be ready:"
echo "     oc get pods -n ${NAMESPACE} -w"
echo ""
echo "  2. Initialize vector database:"
echo "     curl -X POST https://${EVAL_ROUTE}/vectors/initialize"
echo ""
echo "  3. Open the frontend in your browser:"
echo "     https://${FRONTEND_ROUTE}"
echo ""
echo "For more information, see helm/thoughtsapp/README.md"
