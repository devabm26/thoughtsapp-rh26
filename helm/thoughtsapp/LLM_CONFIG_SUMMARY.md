# LLM Configuration - Quick Reference

Choose the method that works best for your workflow:

## 🚀 Quick Methods (Pick One)

### 1. Command Line (Fastest) ⚡
**Best for:** Quick deployments, CI/CD pipelines

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="https://your-llm.com/v1" \
  --set evaluation.llm.apiKey="sk-your-key" \
  --set evaluation.llm.embeddingModel="nomic-embed-text"
```

**Pros:** Quick, scriptable, works with env vars  
**Cons:** API key visible in command history  
📖 **Full guide:** [HELM_CLI_CONFIG.md](./HELM_CLI_CONFIG.md)

---

### 2. Environment Variables
**Best for:** Development, local testing

```bash
export LLM_ENDPOINT="https://your-llm.com/v1"
export LLM_API_KEY="sk-your-key"
export LLM_MODEL="nomic-embed-text"

helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.llm.endpoint="$LLM_ENDPOINT" \
  --set evaluation.llm.apiKey="$LLM_API_KEY" \
  --set evaluation.llm.embeddingModel="$LLM_MODEL"
```

**Pros:** Clean command, reusable  
**Cons:** Need to export vars each time  
📖 **Full guide:** [HELM_CLI_CONFIG.md](./HELM_CLI_CONFIG.md)

---

### 3. ConfigMap/Secret (Most Secure) 🔒
**Best for:** Production, GitOps, keeping secrets out of Helm

```bash
# 1. Create config file
cp llm-config-example.yaml my-llm-config.yaml

# 2. Edit with your LLM details
vim my-llm-config.yaml

# 3. Apply
kubectl apply -f my-llm-config.yaml

# 4. Install chart
helm upgrade --install thoughtsapp . -n thoughts-app
```

**Pros:** Secrets separate from Helm, easy to update live  
**Cons:** Extra step before helm install  
📖 **Full guide:** [QUICKSTART_LLM.md](./QUICKSTART_LLM.md)

---

### 4. Values File
**Best for:** GitOps, repeatable deployments

```yaml
# custom-values.yaml
evaluation:
  llm:
    endpoint: "https://your-llm.com/v1"
    apiKey: "sk-your-key"  # Don't commit this!
    embeddingModel: "nomic-embed-text"
```

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  -f custom-values.yaml
```

**Pros:** Declarative, version controlled (without API key)  
**Cons:** API key in file (use with --set for key)  
📖 **Full guide:** [LLM_CONFIGURATION.md](./LLM_CONFIGURATION.md)

---

### 5. Default (No Configuration)
**Best for:** Demos, testing

```bash
helm upgrade --install thoughtsapp . -n thoughts-app --create-namespace
```

Uses Red Hat workshop LiteLLM endpoint (free, demo-only).

---

## 🎯 Which Method Should I Use?

| Scenario | Recommended Method |
|----------|-------------------|
| Quick test/demo | Default (no config needed) |
| CI/CD pipeline | Command line with `--set` |
| Local development | Environment variables |
| Production deployment | ConfigMap/Secret |
| GitOps workflow | Values file + `--set` for API key |
| Existing LLM with API key | Command line or ConfigMap |

---

## 📝 Common LLM Endpoints

### OpenAI
```bash
--set evaluation.llm.endpoint="https://api.openai.com/v1" \
--set evaluation.llm.apiKey="sk-proj-your-key" \
--set evaluation.llm.embeddingModel="text-embedding-3-small"
```

### Azure OpenAI
```bash
--set evaluation.llm.endpoint="https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT" \
--set evaluation.llm.apiKey="your-azure-key" \
--set evaluation.llm.embeddingModel="text-embedding-ada-002"
```

### Self-hosted Ollama
```bash
--set evaluation.llm.endpoint="http://ollama:11434/v1" \
--set evaluation.llm.apiKey="dummy-key" \
--set evaluation.llm.embeddingModel="nomic-embed-text"
```

### LiteLLM Proxy
```bash
--set evaluation.llm.endpoint="http://litellm-proxy:4000/v1" \
--set evaluation.llm.apiKey="sk-your-litellm-key" \
--set evaluation.llm.embeddingModel="nomic-embed-text"
```

---

## 🔄 Updating LLM Config After Deployment

### Via Helm (updates ConfigMap/Secret)
```bash
helm upgrade thoughtsapp . \
  -n thoughts-app \
  --reuse-values \
  --set evaluation.llm.endpoint="https://new-endpoint.com/v1" \
  --set evaluation.llm.apiKey="new-key"

kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```

### Via kubectl (if using ConfigMap/Secret method)
```bash
kubectl edit configmap evaluation-llm-config -n thoughts-app
kubectl edit secret evaluation-llm-secret -n thoughts-app
kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```

---

## ❌ Disable Evaluation Service

If you don't have an LLM endpoint:

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.enabled=false
```

---

## 📚 Detailed Documentation

- **[HELM_CLI_CONFIG.md](./HELM_CLI_CONFIG.md)** - Complete command line reference
- **[QUICKSTART_LLM.md](./QUICKSTART_LLM.md)** - Step-by-step ConfigMap/Secret setup
- **[LLM_CONFIGURATION.md](./LLM_CONFIGURATION.md)** - All configuration options, including deploying Ollama
- **[README.md](./README.md)** - Main Helm chart documentation

---

## 🆘 Quick Troubleshooting

**Connection refused errors?**
```bash
# Check endpoint is accessible from cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -v https://your-llm-endpoint.com/v1/models
```

**401 Unauthorized?**
```bash
# Verify API key
kubectl get secret evaluation-llm-secret -n thoughts-app \
  -o jsonpath='{.data.OPENSHIFT_AI_API_KEY}' | base64 -d
```

**Values not updating?**
```bash
# Check current values
helm get values thoughtsapp -n thoughts-app

# Force restart
kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```
