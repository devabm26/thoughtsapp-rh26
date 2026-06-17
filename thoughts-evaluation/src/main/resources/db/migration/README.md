# Database Migrations (DEPRECATED)

**These Flyway migration files are no longer used.**

## Why the Change?

The evaluation service has been switched from Flyway to Hibernate ORM for schema management, consistent with the backend service pattern.

### Previous Issues with Flyway:
- V3 migration referenced non-existent `vector_data` column
- V4 migration had conflicts with V1
- Migrations evolved over time causing inconsistencies
- Required manual database fixes on deployment

### Current Approach:

**Hibernate ORM** now handles schema creation automatically:
- **Dev/Test**: `drop-and-create` mode for clean state with dev services
- **Production**: `update` mode to preserve data and apply changes

**pgvector Extension** is created by PostgreSQL initialization script:
- See `helm/thoughtsapp/templates/postgresql.yaml`
- ConfigMap with `/docker-entrypoint-initdb.d/init-pgvector.sh`

## Migration History

For reference, the original migrations were:
- **V1**: Create `evaluation_vectors` table with pgvector extension
- **V2**: Create `thought_evaluations` table
- **V3**: Seed fake vectors (deleted by V4 anyway)
- **V4**: Cleanup migration artifacts

## Seeding Data

Vector embeddings are **not** seeded automatically. They must be generated via the API endpoint:

```bash
POST /vectors/initialize
```

This calls the LLM to generate real embeddings for positive/negative sentiment evaluation.

---

These migration files are retained for historical reference but are not executed.
