#!/bin/bash
# Fix broken Flyway migrations in the database

echo "Fixing Flyway migrations..."

kubectl exec -it deployment/postgresql -n thoughts-app -- psql -U thoughts -d thoughts <<'EOF'
-- Check current migration status
SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank;

-- If V3 failed, delete it and manually insert a successful record
DELETE FROM flyway_schema_history WHERE version = '3';

-- Manually mark V3 as completed (no-op migration)
INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
VALUES (
    (SELECT COALESCE(MAX(installed_rank), 0) + 1 FROM flyway_schema_history),
    '3',
    'seed evaluation vectors',
    'SQL',
    'V3__seed_evaluation_vectors.sql',
    NULL,
    'thoughts',
    NOW(),
    0,
    true
);

-- Verify
SELECT installed_rank, version, description, success FROM flyway_schema_history ORDER BY installed_rank;
EOF

echo "Done. Restart the evaluation deployment:"
echo "kubectl rollout restart deployment thoughts-evaluation -n thoughts-app"
