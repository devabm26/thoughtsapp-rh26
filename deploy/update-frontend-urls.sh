#!/usr/bin/env bash
# Update frontend deployments with actual route URLs

set -e

echo "Getting route URLs..."
BACKEND_URL=$(oc get route thoughts-backend -o jsonpath='{.spec.host}')
EVAL_URL=$(oc get route thoughts-evaluation -o jsonpath='{.spec.host}')

if [ -z "$BACKEND_URL" ] || [ -z "$EVAL_URL" ]; then
    echo "ERROR: Routes not found. Deploy backend and evaluation first."
    exit 1
fi

echo "Backend URL: https://${BACKEND_URL}"
echo "Evaluation URL: https://${EVAL_URL}"

echo ""
echo "Updating thoughts-frontend deployment..."
oc set env deployment/thoughts-frontend \
    NEXT_PUBLIC_API_BASE_URL=https://${BACKEND_URL}

echo "Updating thoughts-admin-ui deployment..."
oc set env deployment/thoughts-admin-ui \
    VITE_API_BASE_URL=https://${BACKEND_URL} \
    VITE_EVALUATION_API_BASE_URL=https://${EVAL_URL}

echo ""
echo "Frontend URLs updated successfully!"
echo "Deployments will automatically restart with new configuration."
