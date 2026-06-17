# LLM Configuration Guide

The evaluation service requires an LLM endpoint to generate embeddings for thought evaluation.

## Configuration Methods

You can configure the LLM service in two ways:

### Method 1: ConfigMap/Secret (Recommended) ✅

**Best for:** Using your existing LLM service with API key

Create a ConfigMap and Secret to override the defaults:

#### Step 1: Copy the example file
```bash
cd helm/thoughtsapp
cp llm-config-example.yaml my-llm-config.yaml
```

#### Step 2: Edit with your LLM details
```yaml
# my-llm-config.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: evaluation-llm-config
  namespace: thoughts-app
data:
  OPENSHIFT_AI_ENDPOINT_URL: "https://your-llm-service.example.com/v1"
  OPENAI_BASE_URL: "https://your-llm-service.example.com/v1"
  EMBEDDING_MODEL_NAME: "nomic-embed-text"

---
apiVersion: v1
kind: Secret
metadata:
  name: evaluation-llm-secret
  namespace: thoughts-app
type: Opaque
stringData:
  OPENSHIFT_AI_API_KEY: "your-actual-api-key"
```

#### Step 3: Apply the configuration
```bash
kubectl apply -f my-llm-config.yaml
```

#### Step 4: Install/upgrade the chart
```bash
helm upgrade --install thoughtsapp . -n thoughts-app --create-namespace
```

**Pros:**
- ✅ Keeps secrets separate from Helm values
- ✅ Easy to update without redeploying
- ✅ Works with existing LLM services
- ✅ API key stays secure

**To update later:**
```bash
kubectl edit configmap evaluation-llm-config -n thoughts-app
kubectl edit secret evaluation-llm-secret -n thoughts-app
kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```

---

### Method 2: Helm Values Override

**Best for:** GitOps workflows, values-based configuration

Override via custom values file:

```yaml
# custom-values.yaml
evaluation:
  llm:
    endpoint: "https://your-llm-service.example.com/v1"
    apiKey: "your-api-key"
    baseUrl: "https://your-llm-service.example.com/v1"
    embeddingModel: "nomic-embed-text"
```

```bash
helm upgrade --install thoughtsapp . -n thoughts-app -f custom-values.yaml
```

---

## Quick Start Options

### Option 1: Red Hat Workshop LiteLLM (Default) ✅

**Best for:** Demos, development, testing

The default configuration uses a free Red Hat workshop LiteLLM endpoint.

**Pros:**
- ✅ Works out of the box
- ✅ No setup required
- ✅ Free for demos

**Cons:**
- ⚠️ Shared endpoint (may have rate limits)
- ⚠️ Not for production use
- ⚠️ No SLA guarantees

**No configuration needed** - just install the chart!

---

### Option 2: Deploy Ollama in Kubernetes

**Best for:** Self-hosted, offline deployments, production

Deploy Ollama alongside the application:

#### Step 1: Create Ollama deployment

```yaml
# ollama-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: thoughts-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama
  template:
    metadata:
      labels:
        app: ollama
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11434
        resources:
          requests:
            cpu: 2000m
            memory: 4Gi
          limits:
            cpu: 4000m
            memory: 8Gi
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
      volumes:
      - name: ollama-data
        persistentVolumeClaim:
          claimName: ollama-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ollama-data
  namespace: thoughts-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: thoughts-app
spec:
  selector:
    app: ollama
  ports:
  - port: 11434
    targetPort: 11434
```

#### Step 2: Pull the embedding model

```bash
kubectl exec -it deployment/ollama -n thoughts-app -- \
  ollama pull nomic-embed-text
```

#### Step 3: Update Helm values

```yaml
# values.yaml or custom-values.yaml
evaluation:
  llm:
    endpoint: http://ollama:11434/v1
    apiKey: dummy-key
    baseUrl: http://ollama:11434/v1
    embeddingModel: nomic-embed-text
```

#### Step 4: Install with custom values

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  -f custom-values.yaml
```

**Pros:**
- ✅ Fully self-hosted
- ✅ No external dependencies
- ✅ Works offline
- ✅ Production-ready

**Cons:**
- ⚠️ Requires GPU for good performance (optional but recommended)
- ⚠️ Higher resource requirements

---

### Option 3: LiteLLM Proxy

**Best for:** Multi-model support, API key management, production

Deploy your own LiteLLM proxy to aggregate multiple LLM providers:

#### Step 1: Deploy LiteLLM

```bash
# Using the LiteLLM Helm chart or Docker
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: litellm-proxy
  namespace: thoughts-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: litellm
  template:
    metadata:
      labels:
        app: litellm
    spec:
      containers:
      - name: litellm
        image: ghcr.io/berriai/litellm:main-latest
        ports:
        - containerPort: 4000
        env:
        - name: LITELLM_MASTER_KEY
          value: "your-master-key"
---
apiVersion: v1
kind: Service
metadata:
  name: litellm-proxy
  namespace: thoughts-app
spec:
  selector:
    app: litellm
  ports:
  - port: 4000
    targetPort: 4000
EOF
```

#### Step 2: Update Helm values

```yaml
evaluation:
  llm:
    endpoint: http://litellm-proxy:4000/v1
    apiKey: your-master-key
    baseUrl: http://litellm-proxy:4000/v1
    embeddingModel: nomic-embed-text
```

**Pros:**
- ✅ Unified API for multiple providers
- ✅ API key management
- ✅ Request caching
- ✅ Fallback support

---

### Option 4: OpenAI API

**Best for:** Quick setup with managed service

Use OpenAI's hosted API:

```yaml
evaluation:
  llm:
    endpoint: https://api.openai.com/v1
    apiKey: "sk-your-actual-openai-api-key"
    baseUrl: https://api.openai.com/v1
    embeddingModel: text-embedding-3-small
```

**Note:** Requires a valid OpenAI API key and will incur costs.

---

## Disable Evaluation Service (Temporary)

If you're not ready to configure an LLM, you can disable the evaluation service:

```yaml
# values.yaml or custom-values.yaml
evaluation:
  enabled: false
```

Then install:

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  -f custom-values.yaml
```

The rest of the application will work normally, but AI-based thought evaluation won't be available.

---

## Testing the LLM Connection

After deployment, test the LLM endpoint:

### 1. Check evaluation service logs

```bash
kubectl logs -n thoughts-app -l app=thoughts-evaluation -f
```

Look for successful connection messages.

### 2. Initialize vectors

```bash
# Get the evaluation service URL
EVAL_URL=$(kubectl get route thoughts-evaluation -n thoughts-app -o jsonpath='{.spec.host}')

# Initialize evaluation vectors (generates embeddings)
curl -X POST https://${EVAL_URL}/vectors/initialize

# Check status
curl https://${EVAL_URL}/vectors/status
```

Expected response:
```json
{
  "vectorsInitialized": true,
  "positiveVectorsCount": 3,
  "negativeVectorsCount": 3,
  "totalVectors": 6
}
```

### 3. Test evaluation

Create a thought and check if it gets evaluated:

```bash
# Backend URL
BACKEND_URL=$(kubectl get route thoughts-backend -n thoughts-app -o jsonpath='{.spec.host}')

# Create a positive thought
curl -X POST https://${BACKEND_URL}/thoughts \
  -H "Content-Type: application/json" \
  -d '{"content":"This is a wonderful day!","author":"Test User"}'

# Check evaluation logs
kubectl logs -n thoughts-app -l app=thoughts-evaluation --tail=20
```

---

## Troubleshooting

### Connection refused: localhost

**Error:** `Connection refused: localhost/127.0.0.1:11434`

**Cause:** Default values.yaml is still using localhost

**Fix:** Update to one of the options above

### Timeout connecting to LLM

**Error:** `Timeout while connecting to LLM endpoint`

**Cause:** LLM service is not ready or unreachable

**Fix:**
- Verify LLM pod is running: `kubectl get pods -n thoughts-app`
- Check LLM service: `kubectl get svc -n thoughts-app`
- Test connectivity from eval pod:
  ```bash
  kubectl exec -it deployment/thoughts-evaluation -n thoughts-app -- \
    curl -v http://ollama:11434/api/tags
  ```

### Invalid API key

**Error:** `401 Unauthorized`

**Cause:** Incorrect API key for the LLM endpoint

**Fix:** Update the `apiKey` in values.yaml

### Model not found

**Error:** `Model 'nomic-embed-text' not found`

**Cause:** Model not pulled in Ollama

**Fix:**
```bash
kubectl exec -it deployment/ollama -n thoughts-app -- \
  ollama pull nomic-embed-text
```

---

## Production Recommendations

For production deployments:

1. **Use production values:**
   ```bash
   helm upgrade --install thoughtsapp . \
     -n thoughts-app \
     -f values-production.yaml \
     -f your-llm-config.yaml
   ```

2. **Use managed LLM services** (Azure OpenAI, AWS Bedrock, etc.) or deploy Ollama with GPU support

3. **Store API keys in external secrets** (Vault, AWS Secrets Manager)

4. **Monitor LLM usage** and set rate limits

5. **Enable request caching** to reduce LLM API calls
