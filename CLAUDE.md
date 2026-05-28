# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

**Positive Thoughts** is a microservices demo application showcasing Red Hat OpenShift, Quarkus, and AI integration. It manages a collection of positive thoughts (quotes) with event-driven AI evaluation. Designed for solutions architects running demos and enterprise Java developers learning cloud-native patterns.

**Key versions:** Java 21, Quarkus 3.31.2, Langchain4j 1.6.0

## Build and Dev Commands

### Quarkus Backend Services

Each Quarkus service has its own Maven wrapper. Quarkus dev services auto-provision PostgreSQL and Kafka containers (requires Docker/Podman running).

```bash
# thoughts-backend (port 8080)
cd thoughts-backend && ./mvnw quarkus:dev

# thoughts-evaluation (port 8088)
cd thoughts-evaluation && ./mvnw quarkus:dev
```

Run tests:
```bash
cd thoughts-backend && ./mvnw test
cd thoughts-evaluation && ./mvnw test

# Single test class
cd thoughts-backend && ./mvnw test -Dtest=ThoughtResourceTest
cd thoughts-evaluation && ./mvnw test -Dtest=EvaluationServiceTest

# Integration tests (skipped by default via skipITs=true)
cd thoughts-backend && ./mvnw verify -DskipITs=false
```

Build:
```bash
cd thoughts-backend && ./mvnw package
cd thoughts-evaluation && ./mvnw package
```

### Frontend (Next.js, port 3000)

```bash
cd thoughts-frontend && npm install && npm run dev
npm test              # Jest
npm run test:watch
```

### Admin UI (Vite + React, port 3003)

```bash
cd thoughts-admin-ui && npm install && npm run dev
npm run lint          # ESLint
npm run test          # Vitest
npm run test:watch
```

## Service Architecture

| Service | Dir | Port | Stack | Role |
|---------|-----|------|-------|------|
| Backend API | `thoughts-backend/` | 8080 | Quarkus, Panache, Kafka producer | CRUD, ratings, publishes to `thoughts.events` topic |
| Evaluation | `thoughts-evaluation/` | 8088 | Quarkus, Langchain4j, Kafka consumer | Consumes events, vector similarity evaluation via LLM embeddings |
| Frontend | `thoughts-frontend/` | 3000 | Next.js, shadcn/ui, Tailwind | Public UI: random thought display + rating |
| Admin UI | `thoughts-admin-ui/` | 3003 | Vite, React, shadcn/ui, TanStack Query | Admin CRUD: manage thoughts, view ratings/evaluations |

### Data Flow
```
User -> thoughts-frontend -> thoughts-backend -> PostgreSQL
                                    | (Kafka: thoughts.events)
                           thoughts-evaluation -> PostgreSQL

Admin -> thoughts-admin-ui -> thoughts-backend (REST)
```

All Quarkus services share a PostgreSQL database. Backend owns schema (Hibernate `drop-and-create` in dev — no Flyway). Evaluation uses Flyway migrations with pgvector (`pgvector/pgvector:pg17` image in dev/test).

### REST Endpoints

**thoughts-backend** (`/thoughts`):
- `GET /thoughts` (paginated), `POST /thoughts`, `GET /thoughts/{id}`, `PUT /thoughts/{id}`, `DELETE /thoughts/{id}`
- `GET /thoughts/random`, `POST /thoughts/thumbsup/{id}`, `POST /thoughts/thumbsdown/{id}`

**thoughts-evaluation**:
- `GET /evaluations` (paginated), `GET /evaluations/thought/{id}`, `GET /evaluations/stats`
- `GET /vectors/status`, `POST /vectors/initialize`

### Package Structure

- **Backend:** `com.redhat.demos.thoughts.*` — model, resource, service, consumer, dto, exception, health, metrics, filter
- **Evaluation:** `com.redhat.demos.evaluation.*` — model, resource, service, consumer, dto, exception

## Key Patterns

- **Entities:** `PanacheEntityBase` with UUID primary keys, `@PrePersist`/`@PreUpdate` lifecycle hooks
- **REST:** JAX-RS `@Path` resources with OpenAPI docs
- **Kafka:** Backend publishes via SmallRye Reactive Messaging (`thoughts-events` channel). Tests use `smallrye-in-memory` connector
- **Evaluation uses Langchain4j** with OpenAI-compatible endpoint (defaults to Ollama at `localhost:11434/v1` in dev). Embedding model: `nomic-embed-text`
- **Qute templates:** `@CheckedTemplate` static inner classes, `{#include layout}` inheritance (used in evaluation service UI)
- **Frontend API client:** Object-based service in `lib/api-client.ts` (`apiClient.getRandomThought()`)
- **Admin UI API client:** Functional exports in `src/lib/api.ts` (`fetchThoughts()`, `createThought()`), uses TanStack Query with react-hook-form + Zod validation. Connects to both backend (port 8080) and evaluation (port 8088) APIs
- **Config profiles:** Quarkus `%dev`/`%test`/`%prod` profiles. Dev services handle infrastructure automatically
- **Health:** SmallRye Health (liveness + readiness) at `/q/health/live` and `/q/health/ready`
- **Metrics:** Micrometer Prometheus

## Environment Variables

| Variable | Service | Default | Purpose |
|----------|---------|---------|---------|
| `NEXT_PUBLIC_API_BASE_URL` | Frontend | `http://localhost:8080` | Backend API URL |
| `VITE_API_BASE_URL` | Admin UI | `http://localhost:8080` | Backend API URL |
| `VITE_EVALUATION_API_BASE_URL` | Admin UI | `http://localhost:8088` | Evaluation API URL |
| `VITE_ADMIN_USER` / `VITE_ADMIN_PASS` | Admin UI | — | Admin login credentials |
| `OPENSHIFT_AI_ENDPOINT_URL` | Evaluation | `http://localhost:11434/v1` | LLM endpoint (Ollama-compatible) |
| `OPENSHIFT_AI_API_KEY` | Evaluation | `dummy-key` | LLM API key |
| `EMBEDDING_MODEL_NAME` | Evaluation | `nomic-embed-text` | Embedding model |
| `EVALUATION_SIMILARITY_THRESHOLD` | Evaluation | `0.85` | Cosine similarity threshold |

## Testing Notes

- Backend tests use Testcontainers (PostgreSQL via dev services) with in-memory Kafka connector
- Evaluation tests use pgvector Docker image and mock the Langchain4j LLM endpoint
- Evaluation service has integration tests for end-to-end flow, error handling, and threshold configuration
- Frontend uses Jest + React Testing Library
- Admin UI uses Vitest + React Testing Library

## Infrastructure

`infrastructure/` contains OpenShift deployment manifests:
- `postgresql/` — Secret, PVC, Deployment, Service + setup/teardown scripts
- `kafka/` — AMQ Streams operator subscription, Kafka cluster, topics + setup/teardown scripts

Dockerfiles for backend services are in `thoughts-backend/src/main/docker/` (JVM, native, native-micro, legacy-jar variants).

## Agent OS Workflow

The `agent-os/` directory contains structured development workflow configuration:

1. `/plan-product` - Creates mission, roadmap, tech stack docs
2. `/shape-spec` - Gathers requirements through questions
3. `/write-spec` - Creates formal spec from requirements
4. `/create-tasks` - Breaks spec into actionable task groups
5. `/implement-tasks` or `/orchestrate-tasks` - Builds the feature

Specs live in `agent-os/specs/YYYY-MM-DD-spec-name/`. Coding standards are in `agent-os/standards/` (global, backend, frontend, testing).
