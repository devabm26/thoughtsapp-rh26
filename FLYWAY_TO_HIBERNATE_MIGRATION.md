# Flyway to Hibernate Migration Guide

## Summary

The `thoughts-evaluation` service has been migrated from Flyway to Hibernate ORM for database schema management.

## Why the Change?

### Problems with Flyway
- V3 migration referenced non-existent `vector_data` column
- V4 migration had conflicts with V1  
- Migrations evolved over time causing inconsistencies
- Required manual database fixes on deployment

### Benefits of Hibernate
- ✅ Consistent with `thoughts-backend` service pattern
- ✅ Schema auto-generated from entity classes
- ✅ No migration file maintenance
- ✅ Simpler deployment process

## Changes Made

### 1. Code Changes
- **pom.xml**: Removed `quarkus-flyway` dependency
- **application.properties**: 
  - Removed Flyway configuration
  - Set `quarkus.hibernate-orm.database.generation=drop-and-create` (dev/test)
  - Set `quarkus.hibernate-orm.database.generation=update` (prod)
- **Migration files**: Deprecated with README explaining the change

### 2. Infrastructure Changes
- **postgresql.yaml**: Added ConfigMap with init script to create pgvector extension
- **evaluation.yaml**: Init container verifies pgvector extension before service starts

### 3. Deployment Flow

```
PostgreSQL starts
    ↓
PostgreSQL init script creates pgvector extension
    ↓
Backend service starts → creates thoughts table via Hibernate
    ↓
Seed job waits for thoughts table → inserts data
    ↓
Evaluation init container verifies:
  - PostgreSQL is ready
  - thoughts table exists
  - pgvector extension exists
    ↓
Evaluation service starts → Hibernate creates evaluation_vectors and thought_evaluations tables
```

## Deploying the Changes

### Fresh Installation
```bash
cd helm/thoughtsapp
helm install thoughtsapp . -n thoughts-app --create-namespace
```

### Upgrading Existing Installation

If you have an existing installation with Flyway data:

```bash
# 1. Backup data if needed
kubectl exec -n thoughts-app deployment/postgresql -- \
  pg_dump -U thoughts thoughts > backup.sql

# 2. Clean up Flyway tables
kubectl exec -n thoughts-app deployment/postgresql -- \
  psql -U thoughts -d thoughts -c "DROP TABLE IF EXISTS flyway_schema_history CASCADE;"
kubectl exec -n thoughts-app deployment/postgresql -- \
  psql -U thoughts -d thoughts -c "DROP TABLE IF EXISTS evaluation_vectors CASCADE;"
kubectl exec -n thoughts-app deployment/postgresql -- \
  psql -U thoughts -d thoughts -c "DROP TABLE IF EXISTS thought_evaluations CASCADE;"

# 3. Rebuild and push new evaluation image
cd thoughts-evaluation
./mvnw clean package
docker build -f src/main/docker/Dockerfile.jvm -t quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest .
docker push quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest

# 4. Upgrade Helm release
cd ../helm/thoughtsapp
helm upgrade thoughtsapp . -n thoughts-app

# 5. Verify
kubectl get pods -n thoughts-app
kubectl logs -n thoughts-app -l app=thoughts-evaluation
```

## Generating Evaluation Vectors

Vectors are **not** auto-seeded. After deployment, initialize them via API:

```bash
# Get the evaluation service URL
EVAL_URL=$(kubectl get route thoughts-evaluation -n thoughts-app -o jsonpath='{.spec.host}')

# Initialize vectors
curl -X POST https://${EVAL_URL}/vectors/initialize

# Verify
curl https://${EVAL_URL}/vectors/status
```

## Entity Classes

The schema is now defined by these entity classes:

- **EvaluationVector** (`evaluation_vectors` table)
  - Stores embedding vectors for positive/negative sentiment
  - Uses custom `VectorConverter` for pgvector type
  
- **ThoughtEvaluation** (`thought_evaluations` table)
  - Stores AI evaluation results for thoughts
  - Links to thoughts via `thought_id`

## Development

### Running Locally
```bash
cd thoughts-evaluation
./mvnw quarkus:dev
```

Dev services automatically:
- Start PostgreSQL with pgvector (`pgvector/pgvector:pg17`)
- Create database schema via Hibernate
- Start Kafka

### Testing
```bash
./mvnw test
./mvnw verify -DskipITs=false  # Integration tests
```

## Troubleshooting

### "relation does not exist" errors
- Ensure pgvector extension is installed: `CREATE EXTENSION IF NOT EXISTS vector;`
- Check init container logs: `kubectl logs -n thoughts-app <pod> -c wait-for-schema`

### Evaluation service won't start
- Verify backend created the `thoughts` table
- Check PostgreSQL init script ran: `kubectl logs -n thoughts-app <postgresql-pod>`
- Verify pgvector extension exists:
  ```bash
  kubectl exec -n thoughts-app deployment/postgresql -- \
    psql -U thoughts -d thoughts -c "\dx vector"
  ```

### Schema changes not applying
- In production, Hibernate uses `update` mode (doesn't drop tables)
- For major schema changes, may need manual migration or recreate tables
