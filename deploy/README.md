# Kubernetes Deployment Manifests

This directory contains Kubernetes/OpenShift manifests for deploying the Positive Thoughts application.

## Prerequisites

- OpenShift 4.x cluster or Kubernetes 1.25+ with Ingress controller
- Red Hat AMQ Streams operator (Strimzi) installed for Kafka
- `oc` or `kubectl` CLI tool

## Deployment Order

### 1. Deploy Infrastructure

First, deploy PostgreSQL and Kafka:

```bash
# Deploy PostgreSQL with pgvector
oc apply -f postgresql.yaml

# Deploy Kafka (requires AMQ Streams/Strimzi operator)
oc apply -f kafka.yaml

# Create evaluation service secret (update values before deploying!)
# Edit evaluation-secret.yaml with your LLM endpoint details
oc apply -f evaluation-secret.yaml

# Wait for infrastructure to be ready
oc wait --for=condition=available --timeout=300s deployment/postgresql
oc wait --for=condition=Ready kafka/thoughtsapp-kafka --timeout=300s

# Seed the database with initial data
oc apply -f postgresql-seed-configmap.yaml
oc apply -f postgresql-seed-job.yaml

# Monitor the seed job
oc logs -f job/postgresql-seed-data
```

### 2. Deploy Backend Services

```bash
# Deploy backend API
oc apply -f thoughts-backend.yaml

# Deploy evaluation service
oc apply -f thoughts-evaluation.yaml

# Wait for services to be ready
oc wait --for=condition=available --timeout=300s deployment/thoughts-backend
oc wait --for=condition=available --timeout=300s deployment/thoughts-evaluation
```

### 3. Deploy Frontend Applications

The frontend applications are pre-configured to use the OpenShift route hostnames. Deploy them directly:

```bash
# Deploy frontend
oc apply -f thoughts-frontend.yaml

# Deploy admin UI
oc apply -f thoughts-admin-ui.yaml

# Wait for deployments
oc wait --for=condition=available --timeout=300s deployment/thoughts-frontend
oc wait --for=condition=available --timeout=300s deployment/thoughts-admin-ui
```

### 4. Get Application URLs

```bash
# Get all route URLs
oc get routes -l app.kubernetes.io/part-of=thoughtsapp

# Or individually
echo "Frontend: https://$(oc get route thoughts-frontend -o jsonpath='{.spec.host}')"
echo "Admin UI: https://$(oc get route thoughts-admin-ui -o jsonpath='{.spec.host}')"
echo "Backend: https://$(oc get route thoughts-backend -o jsonpath='{.spec.host}')"
echo "Evaluation: https://$(oc get route thoughts-evaluation -o jsonpath='{.spec.host}')"
```

## Configuration

### PostgreSQL

Default credentials are defined in `postgresql.yaml`:
- Username: `thoughts`
- Password: `thoughts123`
- Database: `thoughtsdb`

**For production:** Change these values in the Secret before deployment.

### Kafka

The Kafka cluster uses ephemeral storage for demonstration purposes. For production:
- Change `storage.type` from `ephemeral` to `persistent-claim`
- Adjust replica counts and retention settings as needed

### AI/LLM Configuration

The evaluation service expects an LLM endpoint. Update `thoughts-evaluation.yaml`:

```yaml
- name: OPENSHIFT_AI_ENDPOINT_URL
  value: https://your-llm-endpoint/v1
- name: OPENSHIFT_AI_API_KEY
  valueFrom:
    secretKeyRef:
      name: llm-secret
      key: api-key
```

## Resource Requirements

| Service | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|--------------|
| Backend | 250m | 256Mi | 1000m | 512Mi |
| Evaluation | 250m | 512Mi | 1000m | 1Gi |
| Frontend | 100m | 128Mi | 500m | 256Mi |
| Admin UI | 50m | 64Mi | 200m | 128Mi |
| PostgreSQL | 100m | 256Mi | 500m | 512Mi |

Adjust based on your cluster capacity and workload requirements.

## Health Checks

All Quarkus services expose SmallRye Health endpoints:
- Liveness: `/q/health/live`
- Readiness: `/q/health/ready`

## Cleanup

To remove all resources:

```bash
oc delete -f thoughts-admin-ui.yaml
oc delete -f thoughts-frontend.yaml
oc delete -f thoughts-evaluation.yaml
oc delete -f thoughts-backend.yaml
oc delete -f postgresql-seed-job.yaml
oc delete -f postgresql-seed-configmap.yaml
oc delete -f kafka.yaml
oc delete -f postgresql.yaml
```

## Troubleshooting

### Check pod logs

```bash
oc logs -f deployment/thoughts-backend
oc logs -f deployment/thoughts-evaluation
```

### Check database connectivity

```bash
oc rsh deployment/thoughts-backend
curl localhost:8080/q/health/ready
```

### Check Kafka topics

```bash
oc exec -it thoughtsapp-kafka-kafka-0 -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
oc exec -it thoughtsapp-kafka-kafka-0 -- bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic thoughts.events --from-beginning
```

### View events

```bash
oc get events --sort-by='.lastTimestamp' -l app.kubernetes.io/part-of=thoughtsapp
```
