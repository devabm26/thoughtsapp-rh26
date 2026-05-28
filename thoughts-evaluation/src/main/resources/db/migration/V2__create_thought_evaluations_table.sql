-- Migration: Create thought_evaluations table
-- Description: Creates table to store AI evaluation results for thoughts
-- Reversible: Yes (see rollback script)

-- Create thought_evaluations table
CREATE TABLE IF NOT EXISTS thought_evaluations (
    id UUID PRIMARY KEY,
    thought_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('APPROVED', 'REJECTED', 'REMOVED', 'IN_REVIEW')),
    similarity_score DECIMAL(5, 4) NOT NULL,
    evaluated_at TIMESTAMP NOT NULL,
    metadata JSONB
);

-- Create index on thought_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_thought_evaluations_thought_id ON thought_evaluations(thought_id);

-- Create index on status for filtering queries
CREATE INDEX IF NOT EXISTS idx_thought_evaluations_status ON thought_evaluations(status);

-- Rollback script (to be executed manually if needed):
-- DROP INDEX idx_thought_evaluations_status;
-- DROP INDEX idx_thought_evaluations_thought_id;
-- DROP TABLE thought_evaluations;
