-- Migration: Create evaluation_vectors table
-- Description: Creates table to store predefined positive and negative vectors for thought evaluation
-- Reversible: Yes (see rollback script)

-- Create evaluation_vectors table
CREATE TABLE IF NOT EXISTS evaluation_vectors (
    id UUID PRIMARY KEY,
    vector_data JSONB NOT NULL,
    vector_type VARCHAR(20) NOT NULL CHECK (vector_type IN ('POSITIVE', 'NEGATIVE')),
    label VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- Create index on vector_type for filtering queries
CREATE INDEX IF NOT EXISTS idx_evaluation_vectors_type ON evaluation_vectors(vector_type);

-- Rollback script (to be executed manually if needed):
-- DROP INDEX idx_evaluation_vectors_type;
-- DROP TABLE evaluation_vectors;
