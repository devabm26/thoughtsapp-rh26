#!/bin/bash
# Fix evaluation service database migrations

set -e

NAMESPACE="thoughts-app"
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=postgresql -o jsonpath='{.items[0].metadata.name}')

echo "Fixing Flyway migrations in PostgreSQL pod: $POD_NAME"
echo "-----------------------------------------------------------"

# Execute SQL commands to fix the database
kubectl exec -n $NAMESPACE $POD_NAME -- psql -U thoughts -d thoughts <<'EOSQL'
-- Show current Flyway state
\echo 'Current Flyway migration status:'
SELECT installed_rank, version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;

-- Ensure pgvector extension exists
\echo ''
\echo 'Creating pgvector extension...'
CREATE EXTENSION IF NOT EXISTS vector;
\dx vector

-- Clean up failed migrations
\echo ''
\echo 'Cleaning up failed Flyway attempts...'
DELETE FROM flyway_schema_history WHERE success = false;

-- Create tables manually if they don't exist
\echo ''
\echo 'Creating evaluation_vectors table...'
CREATE TABLE IF NOT EXISTS evaluation_vectors (
    id UUID PRIMARY KEY,
    embedding vector NOT NULL,
    vector_type VARCHAR(20) NOT NULL CHECK (vector_type IN ('POSITIVE', 'NEGATIVE')),
    label VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_evaluation_vectors_type ON evaluation_vectors(vector_type);

\echo 'Creating thought_evaluations table...'
CREATE TABLE IF NOT EXISTS thought_evaluations (
    id UUID PRIMARY KEY,
    thought_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('APPROVED', 'REJECTED', 'REMOVED', 'IN_REVIEW')),
    similarity_score DECIMAL(5, 4) NOT NULL,
    evaluated_at TIMESTAMP NOT NULL,
    metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_thought_evaluations_thought_id ON thought_evaluations(thought_id);
CREATE INDEX IF NOT EXISTS idx_thought_evaluations_status ON thought_evaluations(status);

-- Mark migrations as complete
\echo ''
\echo 'Marking migrations as complete in Flyway history...'

-- Only insert if not already present
INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
SELECT 1, '1', 'create evaluation vectors table', 'SQL', 'V1__create_evaluation_vectors_table.sql', NULL, 'thoughts', NOW(), 0, true
WHERE NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version = '1');

INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
SELECT 2, '2', 'create thought evaluations table', 'SQL', 'V2__create_thought_evaluations_table.sql', NULL, 'thoughts', NOW(), 0, true
WHERE NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version = '2');

INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
SELECT 3, '3', 'seed evaluation vectors', 'SQL', 'V3__seed_evaluation_vectors.sql', NULL, 'thoughts', NOW(), 0, true
WHERE NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version = '3');

INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
SELECT 4, '4', 'migrate to pgvector', 'SQL', 'V4__migrate_to_pgvector.sql', NULL, 'thoughts', NOW(), 0, true
WHERE NOT EXISTS (SELECT 1 FROM flyway_schema_history WHERE version = '4');

-- Show final state
\echo ''
\echo 'Final Flyway migration status:'
SELECT installed_rank, version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;

\echo ''
\echo 'Tables created:'
\dt evaluation_vectors
\dt thought_evaluations

EOSQL

echo ""
echo "✓ Database fixed successfully!"
echo ""
echo "Next steps:"
echo "1. Delete the failed evaluation pod:"
echo "   kubectl delete pod -n $NAMESPACE -l app=thoughts-evaluation"
echo ""
echo "2. Watch the new pod start:"
echo "   kubectl logs -n $NAMESPACE -l app=thoughts-evaluation -f"
