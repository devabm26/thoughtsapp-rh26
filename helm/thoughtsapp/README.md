# Thoughts App Helm Chart

A Helm chart for deploying the Positive Thoughts microservices application on OpenShift/Kubernetes.

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.x
- Helm 3.x
- AMQ Streams (Strimzi) Kafka Operator installed
- StorageClass for persistent volumes (optional, can use emptyDir)

## Installing AMQ Streams Operator

Before installing this chart, you need to install the AMQ Streams operator:

### Via OpenShift Console
1. Navigate to Operators → OperatorHub
2. Search for "Red Hat Integration - AMQ Streams"
3. Click Install
4. Select version 2.7.0-7
5. Choose installation mode and namespace

### Via CLI
```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-streams
  namespace: openshift-operators
spec:
  channel: stable
  name: amq-streams
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
  startingCSV: amqstreams.v2.7.0-7
EOF
```

## Installation

### Install with default values
```bash
helm install thoughtsapp ./helm/thoughtsapp -n thoughts-app --create-namespace
```

### Install with your LLM service (via command line)
```bash
helm install thoughtsapp ./helm/thoughtsapp \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="https://your-llm.example.com/v1" \
  --set evaluation.llm.apiKey="your-api-key" \
  --set evaluation.llm.embeddingModel="nomic-embed-text"
```

See [HELM_CLI_CONFIG.md](./HELM_CLI_CONFIG.md) for more command line options.

### Install with custom namespace
```bash
oc new-project my-thoughts-app
helm install thoughtsapp ./helm/thoughtsapp --namespace my-thoughts-app
```

### Install with custom values file
```bash
helm install thoughtsapp ./helm/thoughtsapp --values custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values.

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL deployment | `true` |
| `postgresql.image` | PostgreSQL image with pgvector | `pgvector/pgvector:pg17` |
| `postgresql.database` | Database name | `thoughts` |
| `postgresql.username` | Database username | `thoughts` |
| `postgresql.password` | Database password | `thoughts123` |
| `postgresql.storage.size` | PVC size | `1Gi` |
| `postgresql.storage.className` | Storage class name | `""` (default) |

### Kafka Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kafka.enabled` | Enable Kafka deployment | `true` |
| `kafka.version` | Kafka version | `3.7.0` |
| `kafka.replicas` | Number of Kafka brokers | `3` |
| `kafka.storage.type` | Storage type (ephemeral or persistent-claim) | `ephemeral` |
| `kafka.topic.name` | Topic name for events | `thoughts.events` |
| `kafka.topic.partitions` | Number of partitions | `3` |

### Backend Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend deployment | `true` |
| `backend.image` | Backend container image | `quay.io/redhat_na_ssa/thoughtsapp-backend:latest` |
| `backend.replicas` | Number of replicas | `1` |
| `backend.port` | Service port | `8080` |
| `backend.route.enabled` | Create OpenShift route | `true` |

### Evaluation Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `evaluation.enabled` | Enable evaluation deployment | `true` |
| `evaluation.image` | Evaluation container image | `quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest` |
| `evaluation.replicas` | Number of replicas | `1` |
| `evaluation.port` | Service port | `8088` |
| `evaluation.llm.endpoint` | LLM endpoint URL | `https://litellm-prod.apps.maas.redhatworkshops.io/v1` |
| `evaluation.llm.apiKey` | LLM API key | `dummy-key` |
| `evaluation.llm.embeddingModel` | Embedding model name | `ai/nomic-embed-text-v1.5` |

**Important:** The default LLM endpoint is for demos/testing only. For production or self-hosted deployments, see [LLM_CONFIGURATION.md](./LLM_CONFIGURATION.md) for configuration options including:
- Deploying Ollama in Kubernetes
- Using your own LiteLLM proxy
- Connecting to OpenAI API
- Disabling the evaluation service

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.image` | Frontend container image | `quay.io/redhat_na_ssa/thoughtsapp-frontend:latest` |
| `frontend.replicas` | Number of replicas | `1` |
| `frontend.port` | Service port | `3000` |

### Admin UI Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `adminUi.enabled` | Enable admin UI deployment | `true` |
| `adminUi.image` | Admin UI container image | `quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest` |
| `adminUi.replicas` | Number of replicas | `1` |
| `adminUi.port` | Service port | `8080` |

## Example Custom Values

Create a `custom-values.yaml` file:

```yaml
# Use persistent storage for PostgreSQL
postgresql:
  storage:
    size: 5Gi
    className: gp2

# Use persistent storage for Kafka
kafka:
  storage:
    type: persistent-claim
    size: 20Gi

# Configure LLM endpoint for evaluation service
# See LLM_CONFIGURATION.md for more options
evaluation:
  llm:
    endpoint: http://ollama:11434/v1  # Self-hosted Ollama
    apiKey: dummy-key
    baseUrl: http://ollama:11434/v1
    embeddingModel: nomic-embed-text

# Scale backend for production
backend:
  replicas: 3
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 1Gi
```

Then install:
```bash
helm install thoughtsapp ./helm/thoughtsapp -f custom-values.yaml
```

## Upgrading

```bash
helm upgrade thoughtsapp ./helm/thoughtsapp
```

With custom values:
```bash
helm upgrade thoughtsapp ./helm/thoughtsapp -f custom-values.yaml
```

## Uninstalling

```bash
helm uninstall thoughtsapp
```

**Note:** This will not delete PVCs by default. To delete them:
```bash
oc delete pvc -l app.kubernetes.io/instance=thoughtsapp
```

## Accessing the Application

After installation, get the routes:

```bash
# Frontend
oc get route thoughts-frontend -o jsonpath='{.spec.host}'

# Admin UI
oc get route thoughts-admin-ui -o jsonpath='{.spec.host}'

# Backend API (if route is enabled)
oc get route thoughts-backend -o jsonpath='{.spec.host}'

# Evaluation API (if route is enabled)
oc get route thoughts-evaluation -o jsonpath='{.spec.host}'
```

## Post-Installation Steps

1. **Initialize Vector Database**
   
   After all services are running, initialize the evaluation vectors:
   ```bash
   EVAL_ROUTE=$(oc get route thoughts-evaluation -o jsonpath='{.spec.host}')
   curl -X POST https://$EVAL_ROUTE/vectors/initialize
   ```

2. **Verify Services**
   ```bash
   # Check pod status
   oc get pods
   
   # Check Kafka cluster
   oc get kafka
   
   # Check Kafka topics
   oc get kafkatopic
   ```

3. **Test the Application**
   - Open the frontend route in a browser
   - Click "Show me a thought" to get a random thought
   - Rate thoughts with thumbs up/down
   - Access the admin UI to manage thoughts

## Troubleshooting

### Pods not starting
```bash
# Check pod status
oc get pods

# View pod logs
oc logs <pod-name>

# Describe pod for events
oc describe pod <pod-name>
```

### Database connection issues
```bash
# Check PostgreSQL pod
oc get pods -l app=postgresql

# Verify database connection from backend
oc exec deployment/thoughts-backend -- curl -I localhost:8080/q/health
```

### Kafka connection issues
```bash
# Check Kafka cluster status
oc get kafka thoughtsapp-kafka -o yaml

# Check if topic exists
oc get kafkatopic

# View backend logs for Kafka errors
oc logs deployment/thoughts-backend
```

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Frontend   │────▶│   Backend    │────▶│ PostgreSQL  │
│  (Next.js)  │     │  (Quarkus)   │     │ (pgvector)  │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    Kafka     │
                    │ (AMQ Streams)│
                    └──────────────┘
                           │
                           ▼
┌─────────────┐     ┌──────────────┐
│  Admin UI   │────▶│  Evaluation  │
│   (Vite)    │     │  (Quarkus)   │
└─────────────┘     └──────────────┘
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/yourusername/thoughtsapp/issues
- Documentation: See main README.md in repository root
