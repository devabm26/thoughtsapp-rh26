-- Migration: Cleanup for pgvector
-- Description: Clears any legacy seed data. The embedding column already exists from V1.
-- Real vectors will be generated via POST /vectors/initialize

-- Ensure pgvector extension exists (redundant with init script, but safe)
CREATE EXTENSION IF NOT EXISTS vector;

-- Clear any existing data (V3 seed data would be incompatible)
DELETE FROM evaluation_vectors;
