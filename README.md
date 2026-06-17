# Positive Thoughts - Microservices Demo Application

A cloud-native microservices demonstration built on Red Hat OpenShift, Quarkus, and AI integration. The application manages a collection of positive thoughts (quotes) with event-driven AI evaluation powered by vector embeddings.

Designed for **Solutions Architects** running customer demos and **Enterprise Java developers** learning cloud-native patterns.

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     
│ thoughts-frontend│────▶│ thoughts-backend│────┐
│   (Next.js)     │     │   (Quarkus)     │    │
│  Public Rating  │     │   REST + Kafka  │    │
└─────────────────┘     └────────┬────────┘    │
                                 │             │
┌─────────────────┐              │             │
│thoughts-admin-ui│──────────────┘             │
│     (Vite)      │                            │
│  Admin CRUD UI  │                            │
└─────────────────┘                            │
                                               ▼
                        ┌──────────────────────────────┐
                        │       PostgreSQL             │
                        │     (pgvector ext)           │
                        └──────────────────────────────┘
                                   ▲             ▲
                                   │             │
                        ┌──────────┘             │
                        │                        │
                ┌───────┴─────────┐              │
                │     Kafka       │              │
                │  (AMQ Streams)  │              │
                │ thoughts.events │              │
                └───────┬─────────┘              │
                        │                        │
                        ▼                        │
                ┌────────────────┐               │
                │  thoughts-eval │───────────────┘
                │   (Quarkus)    │
                │  AI Evaluation │
                └────────┬───────┘
                         │
                         ▼
                ┌────────────────┐
                │  LLM Endpoint  │
                │ (litellm/vllm) │
                └────────────────┘
```

## Services

### thoughts-backend (Quarkus 3.31.2, Java 21)

Core REST API for managing thoughts with Kafka event publishing.

**REST Endpoints:**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/thoughts` | GET | List thoughts (paginated, default 20/page) |
| `/thoughts` | POST | Create new thought (publishes event) |
| `/thoughts/{id}` | GET | Get thought by UUID |
| `/thoughts/{id}` | PUT | Update thought (publishes event) |
| `/thoughts/{id}` | DELETE | Delete thought (publishes event) |
| `/thoughts/random` | GET | Get random thought |
| `/thoughts/thumbsup/{id}` | POST | Increment thumbs up counter |
| `/thoughts/thumbsdown/{id}` | POST | Increment thumbs down counter |

**Key Features:**
- PostgreSQL persistence via Hibernate Panache (UUID primary keys)
- Kafka event publishing on create/update/delete to `thoughts.events` topic
- Input validation: content 10-500 chars, author/bio max 200 chars
- CORS enabled for all origins (OpenShift routes)
- Health checks (database, Kafka), Prometheus metrics
- Database seeding: 300+ quotes loaded on first deployment

**Data Model:** `Thought` entity with content, thumbsUp/thumbsDown, status (APPROVED/REJECTED/IN_REVIEW), author, authorBio, timestamps.

### thoughts-evaluation (Quarkus 3.31.2, Java 21)

AI-powered evaluation service using vector embeddings.

**REST Endpoints:**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/evaluations` | GET | List all evaluations (paginated) |
| `/evaluations/thought/{id}` | GET | Get evaluation for specific thought |
| `/evaluations/stats` | GET | Summary stats (total, approved, rejected, avg score) |
| `/vectors/status` | GET | Get vector database status |
| `/vectors/initialize` | POST | Initialize evaluation vectors |

**Key Features:**
- Kafka consumer: processes CREATED events from `thoughts.events`
- Langchain4j integration with OpenAI-compatible LLM endpoint
- Vector similarity evaluation using cosine distance
- PostgreSQL with pgvector extension for vector storage
- Flyway migrations for schema management
- Configurable similarity threshold (default 0.85)
- SmallRye Fault Tolerance: 2 retries with exponential backoff
- Health checks for database, Kafka, and LLM connectivity

### thoughts-frontend (Next.js 16, Standalone Mode)

Public-facing UI for browsing and rating thoughts.

**Features:**
- Random thought display with author attribution
- Thumbs up/down voting (mutually exclusive)
- "Show Another Thought" button for browsing
- Responsive card layout with gradient background
- Runtime backend URL configuration (no build-time hardcoding)
- Internal API proxy routes for production deployment
- Loading states and error handling

**Runtime Configuration:**
- Uses Next.js API routes (`/app/api/[...proxy]/route.ts`) to proxy requests
- Backend URL set via `API_BACKEND_URL` environment variable at runtime
- No NEXT_PUBLIC_* variables needed - fully dynamic

### thoughts-admin-ui (Vite + React, nginx)

Administrative interface for managing thoughts.

**Features:**
- List view: table with content, ratings, status, pagination
- Create form: content, author, bio with validation
- Edit form: update content, change status, view ratings
- Delete: confirmation dialog
- Built with shadcn/ui, react-hook-form, Zod validation
- TanStack Query for data fetching and caching

**Runtime Configuration:**
- nginx proxy configuration for backend/evaluation API
- Environment variables: `API_BACKEND_URL`, `EVALUATION_API_URL`
- Proxies `/api/*` to backend, `/evaluation-api/*` to evaluation service

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend Framework | Quarkus 3.31.2 (Java 21) |
| Frontend Frameworks | Next.js 16 (standalone), Vite + React |
| UI Components | shadcn/ui (Radix UI + Tailwind CSS) |
| Database | PostgreSQL 17 with pgvector extension |
| ORM | Hibernate Panache |
| Migrations | Flyway (evaluation service) |
| Messaging | Apache Kafka via AMQ Streams 2.7.0-7 |
| AI Integration | Langchain4j 1.6.0 with OpenAI-compatible endpoint |
| Platform | Red Hat OpenShift 4.x |
| Build Tools | Maven 3.9+ (backend), npm (frontend) |
| Container Runtime | Podman |
| Deployment | Helm 3.x |
| Testing | JUnit 5, REST Assured, Testcontainers, Jest, Vitest |
| Observability | Micrometer/Prometheus, SmallRye Health |

## Local Development

### Prerequisites

- **Java 21** (enforced via maven-enforcer-plugin)
- **Maven 3.9+**
- **Node.js 18+** and npm
- **Docker or Podman** (for Quarkus dev services)
- **Optional:** Ollama or litellm for local LLM endpoint

### Backend Services

Both Quarkus services use dev services that auto-provision PostgreSQL and Kafka containers.

```bash
# thoughts-backend (port 8080)
cd thoughts-backend
./mvnw quarkus:dev

# thoughts-evaluation (port 8088)
cd thoughts-evaluation
./mvnw quarkus:dev
```

**Dev Services Auto-Provisioning:**
- PostgreSQL (Testcontainers)
- Kafka with ZooKeeper
- All connection strings configured automatically

### Frontend Applications

```bash
# thoughts-frontend (port 3000)
cd thoughts-frontend
npm install
npm run dev

# thoughts-admin-ui (port 3003)
cd thoughts-admin-ui
npm install
npm run dev
```

### Running Tests

```bash
# Backend tests (with Testcontainers)
cd thoughts-backend && ./mvnw test

# Evaluation tests
cd thoughts-evaluation && ./mvnw test

# Frontend tests
cd thoughts-frontend && npm test

# Admin UI tests
cd thoughts-admin-ui && npm run test
```

## Building Container Images

All services use a **two-step build process** to avoid QEMU emulation issues on ARM Macs:

1. **Step 1:** Build artifacts locally with native architecture
2. **Step 2:** Package in runtime-only container for linux/amd64

### Backend Services

```bash
# thoughts-backend
cd thoughts-backend
./podman-build.sh
# Builds uber-jar with Java 21, packages in UBI9 OpenJDK 21 runtime container
# Pushes to quay.io/redhat_na_ssa/thoughtsapp-backend:latest

# thoughts-evaluation
cd thoughts-evaluation
./podman-build.sh
# Pushes to quay.io/redhat_na_ssa/thoughtsapp-evaluation:latest
```

**Build scripts automatically:**
- Set Java 21 via `JAVA_HOME` (enforced by maven-enforcer-plugin)
- Build uber-jar with `-DskipTests`
- Package in runtime-only container
- Tag for container registry
- Push to quay.io

### Frontend Services

```bash
# thoughts-frontend
cd thoughts-frontend
./podman-build.sh
# Builds Next.js standalone output, packages with Node.js 20 minimal
# Pushes to quay.io/redhat_na_ssa/thoughtsapp-frontend:latest

# thoughts-admin-ui
cd thoughts-admin-ui
./podman-build.sh
# Builds Vite static assets, packages with nginx + runtime proxy config
# Pushes to quay.io/redhat_na_ssa/thoughtsapp-admin-ui:latest
```

## OpenShift Deployment

### Option 1: Helm Chart (Recommended)

The Helm chart provides a complete deployment with all dependencies.

**Prerequisites:**
- AMQ Streams operator installed in cluster
- OpenShift cluster with ingress domain

**Basic Installation:**

```bash
cd helm

# Install with auto-detected cluster domain
./install.sh

# Or specify cluster domain explicitly
./install.sh --domain apps.cluster-abc.example.com

# With custom values file
./install.sh --values values-production.yaml
```

**What Gets Deployed:**
- PostgreSQL with pgvector (PVC-backed)
- AMQ Streams Kafka cluster (3 replicas)
- Kafka topic: `thoughts.events`
- Backend service with Routes
- Evaluation service with Routes
- Frontend with Routes
- Admin UI with Routes
- Database seeding Job (auto-cleanup after 5 minutes)
- LLM endpoint secret (configure with your endpoint)

**Post-Installation:**

```bash
# Wait for all pods to be ready
oc get pods -w

# Initialize vector database for AI evaluation
EVAL_ROUTE=$(oc get route thoughts-evaluation -o jsonpath='{.spec.host}')
curl -X POST https://$EVAL_ROUTE/vectors/initialize

# Get application URLs
oc get routes
```

**Customization:**

Edit `helm/thoughtsapp/values.yaml` or create a custom values file:

```yaml
# Example: Production settings
postgresql:
  storage:
    size: 10Gi
    className: gp3

kafka:
  replicas: 3
  storage:
    type: persistent-claim
    size: 50Gi

backend:
  replicas: 3

evaluation:
  replicas: 2
  llm:
    endpoint: http://litellm-proxy:4000/v1
    apiKey: sk-your-api-key
    embeddingModel: nomic-embed-text
```

**Uninstall:**

```bash
cd helm
helm uninstall thoughtsapp
```

### Option 2: Manual YAML Deployment

Deploy individual components using manifests in `deploy/` directory.

```bash
# 1. Deploy PostgreSQL
oc apply -f deploy/postgresql.yaml
oc apply -f deploy/postgresql-seed-configmap.yaml
oc apply -f deploy/postgresql-seed-job.yaml

# 2. Deploy Kafka (requires AMQ Streams operator)
oc apply -f deploy/kafka.yaml

# 3. Deploy evaluation secret (configure your LLM endpoint)
oc apply -f deploy/evaluation-secret.yaml

# 4. Deploy services
oc apply -f deploy/thoughts-backend.yaml
oc apply -f deploy/thoughts-evaluation.yaml
oc apply -f deploy/thoughts-frontend.yaml
oc apply -f deploy/thoughts-admin-ui.yaml
```

## Environment Variables

### thoughts-backend

| Variable | Description | Default |
|----------|-------------|---------|
| `QUARKUS_DATASOURCE_JDBC_URL` | PostgreSQL JDBC URL | jdbc:postgresql://postgresql:5432/thoughts |
| `QUARKUS_DATASOURCE_USERNAME` | Database username | thoughts |
| `QUARKUS_DATASOURCE_PASSWORD` | Database password | thoughts123 |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka brokers | thoughtsapp-kafka-kafka-bootstrap:9092 |
| `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION` | Hibernate schema mode | update (prod) |

### thoughts-evaluation

| Variable | Description | Default |
|----------|-------------|---------|
| `QUARKUS_DATASOURCE_JDBC_URL` | PostgreSQL JDBC URL | jdbc:postgresql://postgresql:5432/thoughts |
| `QUARKUS_DATASOURCE_USERNAME` | Database username | thoughts |
| `QUARKUS_DATASOURCE_PASSWORD` | Database password | thoughts123 |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka brokers | thoughtsapp-kafka-kafka-bootstrap:9092 |
| `OPENSHIFT_AI_ENDPOINT_URL` | LLM API base URL | http://localhost:11434/v1 |
| `OPENSHIFT_AI_API_KEY` | LLM API key | dummy-key |
| `OPENAI_BASE_URL` | OpenAI-compatible base URL | http://localhost:11434/v1 |
| `EMBEDDING_MODEL_NAME` | Embedding model | nomic-embed-text |
| `EVALUATION_SIMILARITY_THRESHOLD` | Threshold (0.0-1.0) | 0.85 |

### thoughts-frontend

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BACKEND_URL` | Backend service URL (runtime) | http://thoughts-backend:8080 |

### thoughts-admin-ui

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BACKEND_URL` | Backend service URL (runtime) | http://thoughts-backend:8080 |
| `EVALUATION_API_URL` | Evaluation service URL (runtime) | http://thoughts-evaluation:8088 |

## Database Schema

Three tables managed by Hibernate (backend) and Flyway (evaluation):

### thoughts
Core thought content with ratings and status.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| content | VARCHAR(500) | Thought text |
| author | VARCHAR(200) | Author name |
| author_bio | VARCHAR(200) | Author bio |
| thumbs_up | INTEGER | Positive votes |
| thumbs_down | INTEGER | Negative votes |
| status | VARCHAR(20) | APPROVED/REJECTED/IN_REVIEW |
| created_at | TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | Last update time |

### thought_evaluations
AI evaluation results.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| thought_id | UUID | Foreign key to thoughts |
| status | VARCHAR(20) | APPROVED/REJECTED |
| similarity_score | DECIMAL(5,4) | Cosine similarity score |
| evaluated_at | TIMESTAMP | Evaluation time |
| metadata | JSONB | Additional metadata |

### evaluation_vectors
Pre-computed reference vectors for similarity comparison (pgvector).

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| embedding | vector | Vector embedding |
| vector_type | VARCHAR(20) | POSITIVE/NEGATIVE |
| label | VARCHAR(255) | Vector label |
| created_at | TIMESTAMP | Creation time |

## Architecture Patterns

### Event-Driven Architecture
- Backend publishes events to Kafka on create/update/delete
- Evaluation service consumes events asynchronously
- Decoupled services with eventual consistency

### Runtime Configuration
- Frontend/Admin UI use runtime environment variables
- No build-time URL hardcoding
- Portable across clusters without rebuild

### Two-Step Container Builds
- Local compilation with native architecture
- Runtime-only containers for deployment
- Avoids QEMU emulation issues on ARM Macs

### Service Mesh Ready
- Internal service communication via Kubernetes DNS
- Health checks for liveness and readiness
- Prometheus metrics for observability

## Testing Strategy

### Backend Tests
- Unit tests with JUnit 5
- REST API tests with REST Assured
- Integration tests with Testcontainers
- Mock LLM endpoint for evaluation tests

### Frontend Tests
- Component tests with React Testing Library
- API client tests with Jest/Vitest
- End-to-end tests with Playwright (optional)

### Test Coverage
- Backend: ~85% code coverage
- Evaluation: ~90% code coverage
- Frontend: Component and integration tests

## Troubleshooting

### Backend won't start - "evaluation_vectors" error
**Problem:** Backend tries to manage evaluation service's table.

**Solution:** Remove `EvaluationVector` entity from backend (already done in latest version).

### Frontend gets 403 on thumbsup/thumbsdown
**Problem:** CORS not configured in backend.

**Solution:** Backend now has CORS enabled for all origins via `/http.*/` regex pattern.

### Container build fails with QEMU error
**Problem:** Cross-architecture builds on ARM Mac.

**Solution:** Use two-step build scripts (`./podman-build.sh`) that compile locally then package.

### LLM endpoint not responding
**Problem:** Evaluation service can't reach LLM.

**Solution:** Check `OPENSHIFT_AI_ENDPOINT_URL` points to running LLM service (litellm, vllm, or Ollama).

### Kafka connection refused
**Problem:** AMQ Streams operator not installed or topic missing.

**Solution:** Install AMQ Streams operator and ensure `thoughtsapp-kafka-kafka-bootstrap` service exists.

## Project Structure

```
thoughtsapp-rh26/
├── thoughts-backend/          # Quarkus REST API service
│   ├── src/main/java/         # Java source code
│   ├── src/main/resources/    # application.properties, import.sql
│   ├── src/test/              # Unit and integration tests
│   ├── pom.xml                # Maven dependencies (enforces Java 21)
│   ├── ContainerFile.runtime  # Runtime-only container definition
│   └── podman-build.sh        # Two-step build script
│
├── thoughts-evaluation/       # Quarkus AI evaluation service
│   ├── src/main/java/         # Java source code
│   ├── src/main/resources/    # application.properties
│   │   └── db/migration/      # Flyway migrations (V1, V2, V3, V4)
│   ├── src/test/              # Unit and integration tests
│   ├── pom.xml                # Maven dependencies (enforces Java 21)
│   ├── ContainerFile.runtime  # Runtime-only container definition
│   └── podman-build.sh        # Two-step build script
│
├── thoughts-frontend/         # Next.js public UI
│   ├── app/                   # Next.js app directory
│   │   ├── api/[...proxy]/    # Runtime API proxy routes
│   │   └── page.tsx           # Main page component
│   ├── components/            # React components
│   ├── lib/                   # API client, utilities
│   ├── next.config.ts         # Next.js config (standalone mode)
│   ├── ContainerFile.runtime  # Runtime-only container definition
│   └── podman-build.sh        # Two-step build script
│
├── thoughts-admin-ui/         # Vite + React admin UI
│   ├── src/                   # React source code
│   ├── nginx.conf.template    # nginx config template
│   ├── proxy.conf.template    # nginx proxy config template
│   ├── ContainerFile.runtime  # Runtime-only container with nginx
│   └── podman-build.sh        # Two-step build script
│
├── deploy/                    # OpenShift deployment manifests
│   ├── postgresql.yaml        # PostgreSQL database
│   ├── postgresql-seed-configmap.yaml  # Seed data
│   ├── postgresql-seed-job.yaml        # Database seeding job
│   ├── evaluation-secret.yaml          # LLM endpoint configuration
│   ├── kafka.yaml                      # AMQ Streams Kafka cluster
│   ├── thoughts-backend.yaml           # Backend deployment + route
│   ├── thoughts-evaluation.yaml        # Evaluation deployment + route
│   ├── thoughts-frontend.yaml          # Frontend deployment + route
│   └── thoughts-admin-ui.yaml          # Admin UI deployment + route
│
├── helm/                      # Helm chart for complete deployment
│   ├── thoughtsapp/           # Chart directory
│   │   ├── Chart.yaml         # Chart metadata
│   │   ├── values.yaml        # Default configuration
│   │   ├── values-production.yaml  # Production overrides
│   │   ├── templates/         # Kubernetes manifest templates
│   │   └── README.md          # Chart documentation
│   └── install.sh             # Installation script with auto-detection
│
└── README.md                  # This file
```

## Contributing

This is a demonstration application. For issues or questions:
- Check existing documentation in `README.md` and `helm/thoughtsapp/README.md`
- Review CLAUDE.md for project context and conventions
- Open an issue for bugs or feature requests

## License

[Add your license here]

## Resources

- [Quarkus Documentation](https://quarkus.io/guides/)
- [Next.js Documentation](https://nextjs.org/docs)
- [AMQ Streams Documentation](https://access.redhat.com/documentation/en-us/red_hat_amq_streams)
- [PostgreSQL pgvector](https://github.com/pgvector/pgvector)
- [Langchain4j](https://docs.langchain4j.dev/)
- [Helm Charts](https://helm.sh/docs/)
