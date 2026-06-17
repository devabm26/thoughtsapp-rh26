# Quick Start: Configure Your LLM Service

Follow these steps to configure the evaluation service with your existing LLM endpoint and API key.

## Steps

### 1. Copy the example configuration
```bash
cd helm/thoughtsapp
cp llm-config-example.yaml my-llm-config.yaml
```

### 2. Edit with your LLM details
```bash
# Open in your editor
vim my-llm-config.yaml  # or nano, code, etc.
```

Update these values:
```yaml
# ConfigMap - Non-sensitive configuration
data:
  OPENSHIFT_AI_ENDPOINT_URL: "https://YOUR-LLM-ENDPOINT/v1"
  OPENAI_BASE_URL: "https://YOUR-LLM-ENDPOINT/v1"
  EMBEDDING_MODEL_NAME: "your-model-name"

# Secret - Your API key
stringData:
  OPENSHIFT_AI_API_KEY: "your-actual-api-key-here"
```

### 3. Create the namespace (if it doesn't exist)
```bash
kubectl create namespace thoughts-app
```

### 4. Apply your LLM configuration
```bash
kubectl apply -f my-llm-config.yaml
```

Verify it was created:
```bash
kubectl get configmap evaluation-llm-config -n thoughts-app
kubectl get secret evaluation-llm-secret -n thoughts-app
```

### 5. Install the Helm chart
```bash
helm upgrade --install thoughtsapp . -n thoughts-app --create-namespace
```

### 6. Verify the evaluation service started
```bash
# Check pods
kubectl get pods -n thoughts-app

# Check evaluation logs
kubectl logs -n thoughts-app -l app=thoughts-evaluation -f
```

You should see the evaluation service connect to your LLM endpoint successfully!

### 7. Initialize evaluation vectors
```bash
# Get the evaluation service URL
EVAL_URL=$(kubectl get route thoughts-evaluation -n thoughts-app -o jsonpath='{.spec.host}')

# Initialize vectors (this calls your LLM to generate embeddings)
curl -X POST https://${EVAL_URL}/vectors/initialize

# Check status
curl https://${EVAL_URL}/vectors/status
```

## Updating Configuration Later

If you need to change the LLM endpoint or API key after deployment:

```bash
# Method 1: Edit in-place
kubectl edit configmap evaluation-llm-config -n thoughts-app
kubectl edit secret evaluation-llm-secret -n thoughts-app

# Method 2: Reapply your file
kubectl apply -f my-llm-config.yaml

# Restart the evaluation service to pick up changes
kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```

## Common LLM Endpoints

**OpenAI:**
```yaml
OPENSHIFT_AI_ENDPOINT_URL: "https://api.openai.com/v1"
OPENAI_BASE_URL: "https://api.openai.com/v1"
EMBEDDING_MODEL_NAME: "text-embedding-3-small"
```

**Azure OpenAI:**
```yaml
OPENSHIFT_AI_ENDPOINT_URL: "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT"
OPENAI_BASE_URL: "https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT"
EMBEDDING_MODEL_NAME: "text-embedding-ada-002"
```

**Self-hosted Ollama:**
```yaml
OPENSHIFT_AI_ENDPOINT_URL: "http://ollama:11434/v1"
OPENAI_BASE_URL: "http://ollama:11434/v1"
EMBEDDING_MODEL_NAME: "nomic-embed-text"
```

**LiteLLM Proxy:**
```yaml
OPENSHIFT_AI_ENDPOINT_URL: "http://litellm-proxy:4000/v1"
OPENAI_BASE_URL: "http://litellm-proxy:4000/v1"
EMBEDDING_MODEL_NAME: "nomic-embed-text"
```

## Troubleshooting

**"Connection refused" errors:**
- Verify the endpoint URL is correct and accessible from the cluster
- Check if your LLM service is running: `curl -v https://your-llm-endpoint/v1/models`

**"401 Unauthorized" errors:**
- Check your API key is correct in the secret
- Verify the API key has access to the embedding model

**"Model not found" errors:**
- Verify the model name matches what's available in your LLM service
- For Ollama, pull the model first: `kubectl exec deployment/ollama -- ollama pull nomic-embed-text`

## Security Best Practices

1. **Never commit my-llm-config.yaml to git** - it contains your API key
2. **Use Kubernetes Secrets** for API keys (already configured)
3. **Consider using External Secrets Operator** for production to pull from Vault/AWS Secrets Manager
4. **Rotate API keys regularly** and update the secret

## Need Help?

See [LLM_CONFIGURATION.md](./LLM_CONFIGURATION.md) for detailed configuration options including:
- Deploying Ollama in Kubernetes
- Setting up LiteLLM proxy
- Using managed services (Azure OpenAI, AWS Bedrock)
- Disabling the evaluation service
