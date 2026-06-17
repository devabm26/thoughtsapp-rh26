# Helm Command Line Configuration

Configure LLM settings directly via `helm upgrade` command line flags.

## Method 1: Direct --set Flags

### Basic Usage
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="https://your-llm.example.com/v1" \
  --set evaluation.llm.apiKey="sk-your-api-key-here" \
  --set evaluation.llm.embeddingModel="nomic-embed-text"
```

### With All LLM Options
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="https://api.openai.com/v1" \
  --set evaluation.llm.baseUrl="https://api.openai.com/v1" \
  --set evaluation.llm.apiKey="sk-proj-xxxxxxxxxxxxx" \
  --set evaluation.llm.embeddingModel="text-embedding-3-small"
```

## Method 2: Using Environment Variables

### Step 1: Set environment variables
```bash
export LLM_ENDPOINT="https://your-llm.example.com/v1"
export LLM_API_KEY="sk-your-api-key-here"
export LLM_MODEL="nomic-embed-text"
```

### Step 2: Use them in helm upgrade
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="$LLM_ENDPOINT" \
  --set evaluation.llm.apiKey="$LLM_API_KEY" \
  --set evaluation.llm.embeddingModel="$LLM_MODEL"
```

### Using .env File (Bash)
```bash
# Create .env file
cat > .env <<EOF
LLM_ENDPOINT=https://your-llm.example.com/v1
LLM_API_KEY=sk-your-api-key-here
LLM_MODEL=nomic-embed-text
EOF

# Load and use
source .env
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --create-namespace \
  --set evaluation.llm.endpoint="$LLM_ENDPOINT" \
  --set evaluation.llm.apiKey="$LLM_API_KEY" \
  --set evaluation.llm.embeddingModel="$LLM_MODEL"
```

## Method 3: Combining --set with Values Files

You can mix values files with --set overrides:

```bash
# Install with production values, but override LLM endpoint
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  -f values-production.yaml \
  --set evaluation.llm.endpoint="$LLM_ENDPOINT" \
  --set evaluation.llm.apiKey="$LLM_API_KEY"
```

## Method 4: --set-string for Complex Values

If your API key or endpoint has special characters:

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set-string evaluation.llm.apiKey='sk-proj-abc123!@#$%^&*()' \
  --set-string evaluation.llm.endpoint='https://my-llm.com/v1?param=value'
```

## Common Examples

### OpenAI
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.llm.endpoint="https://api.openai.com/v1" \
  --set evaluation.llm.apiKey="sk-proj-your-key" \
  --set evaluation.llm.embeddingModel="text-embedding-3-small"
```

### Azure OpenAI
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.llm.endpoint="https://your-resource.openai.azure.com/openai/deployments/your-deployment" \
  --set evaluation.llm.apiKey="your-azure-key" \
  --set evaluation.llm.embeddingModel="text-embedding-ada-002"
```

### Self-hosted Ollama
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.llm.endpoint="http://ollama:11434/v1" \
  --set evaluation.llm.apiKey="dummy-key" \
  --set evaluation.llm.embeddingModel="nomic-embed-text"
```

### LiteLLM Proxy
```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.llm.endpoint="http://litellm-proxy:4000/v1" \
  --set evaluation.llm.apiKey="sk-your-litellm-key" \
  --set evaluation.llm.embeddingModel="nomic-embed-text"
```

## Using with CI/CD

### GitHub Actions Example
```yaml
- name: Deploy with LLM config
  run: |
    helm upgrade --install thoughtsapp ./helm/thoughtsapp \
      -n thoughts-app \
      --create-namespace \
      --set evaluation.llm.endpoint="${{ secrets.LLM_ENDPOINT }}" \
      --set evaluation.llm.apiKey="${{ secrets.LLM_API_KEY }}" \
      --set evaluation.llm.embeddingModel="nomic-embed-text"
```

### GitLab CI Example
```yaml
deploy:
  script:
    - helm upgrade --install thoughtsapp ./helm/thoughtsapp
        -n thoughts-app
        --create-namespace
        --set evaluation.llm.endpoint="$LLM_ENDPOINT"
        --set evaluation.llm.apiKey="$LLM_API_KEY"
        --set evaluation.llm.embeddingModel="$LLM_MODEL"
```

### Jenkins Example
```groovy
stage('Deploy') {
    steps {
        withCredentials([
            string(credentialsId: 'llm-endpoint', variable: 'LLM_ENDPOINT'),
            string(credentialsId: 'llm-api-key', variable: 'LLM_API_KEY')
        ]) {
            sh """
                helm upgrade --install thoughtsapp ./helm/thoughtsapp \
                  -n thoughts-app \
                  --create-namespace \
                  --set evaluation.llm.endpoint="${LLM_ENDPOINT}" \
                  --set evaluation.llm.apiKey="${LLM_API_KEY}" \
                  --set evaluation.llm.embeddingModel="nomic-embed-text"
            """
        }
    }
}
```

## Updating Only LLM Config

To update just the LLM configuration without changing other settings:

```bash
helm upgrade thoughtsapp . \
  -n thoughts-app \
  --reuse-values \
  --set evaluation.llm.endpoint="https://new-endpoint.com/v1" \
  --set evaluation.llm.apiKey="new-api-key"
```

**Note:** `--reuse-values` keeps all other existing values.

## Verify Configuration

After deployment, check the ConfigMap and Secret:

```bash
# View ConfigMap (non-sensitive)
kubectl get configmap evaluation-llm-config -n thoughts-app -o yaml

# View Secret (base64 encoded)
kubectl get secret evaluation-llm-secret -n thoughts-app -o yaml

# Decode Secret
kubectl get secret evaluation-llm-secret -n thoughts-app \
  -o jsonpath='{.data.OPENSHIFT_AI_API_KEY}' | base64 -d
```

## Restart Evaluation Service

After changing LLM config, restart the evaluation pods:

```bash
kubectl rollout restart deployment thoughts-evaluation -n thoughts-app
```

## All Available LLM Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `evaluation.llm.endpoint` | LLM endpoint URL | Red Hat workshop LiteLLM |
| `evaluation.llm.baseUrl` | OpenAI base URL (usually same as endpoint) | Same as endpoint |
| `evaluation.llm.apiKey` | API key for authentication | `dummy-key` |
| `evaluation.llm.embeddingModel` | Name of the embedding model | `ai/nomic-embed-text-v1.5` |

## Disable Evaluation Service

If you don't have an LLM endpoint yet:

```bash
helm upgrade --install thoughtsapp . \
  -n thoughts-app \
  --set evaluation.enabled=false
```

## Security Best Practices

1. **Never log API keys**
   ```bash
   # Bad - key visible in logs
   echo "Installing with API key: $LLM_API_KEY"
   
   # Good - no logging
   helm upgrade --install ... --set evaluation.llm.apiKey="$LLM_API_KEY"
   ```

2. **Use secrets management in CI/CD**
   - GitHub Secrets
   - GitLab CI/CD Variables
   - Jenkins Credentials
   - HashiCorp Vault

3. **Avoid shell history**
   ```bash
   # Prefix with space to avoid history (if HISTCONTROL=ignorespace)
    helm upgrade --install ... --set evaluation.llm.apiKey="secret"
   
   # Or clear history after
   history -d $(history 1 | awk '{print $1}')
   ```

4. **Use values file for non-sensitive config**
   ```yaml
   # public-values.yaml (can commit to git)
   evaluation:
     llm:
       endpoint: "https://api.openai.com/v1"
       embeddingModel: "text-embedding-3-small"
   ```
   
   ```bash
   # API key via --set (from secret store)
   helm upgrade --install thoughtsapp . \
     -n thoughts-app \
     -f public-values.yaml \
     --set evaluation.llm.apiKey="$LLM_API_KEY"
   ```

## Troubleshooting

**Values not updating?**
```bash
# Use --reuse-values carefully - it can keep old values
# Instead, use -f to specify all values explicitly
helm upgrade thoughtsapp . -n thoughts-app -f values.yaml
```

**Need to see what values were used?**
```bash
helm get values thoughtsapp -n thoughts-app
```

**Special characters in values?**
```bash
# Use --set-string for complex strings
helm upgrade --install thoughtsapp . \
  --set-string evaluation.llm.apiKey='complex!@#$%value'
```
