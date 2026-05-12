# AI Evaluation Service

A Quarkus microservice that evaluates user-submitted "thoughts" for positive or negative sentiment using AI-generated vector embeddings and cosine similarity. It consumes thought-created events from Kafka, compares each thought against a set of reference vectors, and classifies thoughts as APPROVED or REJECTED.

## How It Works

1. The `thoughts-backend` service publishes a Kafka event whenever a new thought is created.
2. `ThoughtEvaluationConsumer` receives the event from the `thoughts.events` topic.
3. `EmbeddingService` calls an OpenAI-compatible embedding model (e.g. hosted on OpenShift AI) via Langchain4j to generate a vector embedding of the thought's text content.
4. `VectorSimilarityService` computes the cosine similarity between the thought's embedding and each pre-seeded reference vector stored in the `evaluation_vectors` table.
5. If the thought's similarity to any **negative** reference vector exceeds the configured threshold (default 0.85), the thought is marked **REJECTED**. Otherwise it is **APPROVED**.
6. The evaluation result (status, similarity score, timestamp) is persisted to the `thought_evaluations` table.

### Reference Vectors

The service uses 6 reference vectors — 3 positive, 3 negative — that define the evaluation baseline:

| Type | Label |
|------|-------|
| POSITIVE | Encouraging and uplifting language |
| POSITIVE | Optimistic and hopeful perspective |
| POSITIVE | Gratitude and appreciation expressions |
| NEGATIVE | Hateful or discriminatory language |
| NEGATIVE | Violent or threatening content |
| NEGATIVE | Profanity and abusive language |

These are initially seeded by a Flyway migration (V3) with placeholder values. The `/vectors/initialize` endpoint regenerates them with real embeddings from the configured AI model.

## Requirements

- **Java 25**
- **Maven 3.9+**
- **PostgreSQL** (Quarkus Dev Services auto-provisions one in dev/test mode)
- **Apache Kafka** (Quarkus Dev Services auto-provisions one in dev/test mode)
- **OpenAI-compatible embedding model endpoint** (e.g. OpenShift AI serving `text-embedding-ada-002`)

## Environment Variables
```
export EMBEDDING_MODEL_NAME=nomic-embed-text-v1-5
export OPENSHIFT_AI_API_KEY=<<LITELLM_API_KEY>>
export OPENAI_BASE_URL="https://litellm-prod.apps.maas.redhatworkshops.io/v1"
```

### Database (production only — dev/test use Quarkus Dev Services)

| Variable | Description |
|----------|-------------|
| `QUARKUS_DATASOURCE_USERNAME` | PostgreSQL username |
| `QUARKUS_DATASOURCE_PASSWORD` | PostgreSQL password |
| `QUARKUS_DATASOURCE_JDBC_URL` | JDBC connection URL (e.g. `jdbc:postgresql://host:5432/dbname`) |

### Kafka (production only)

| Variable | Description | Default |
|----------|-------------|---------|
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker address | — |
| `KAFKA_THOUGHTS_TOPIC` | Topic name for thought events | `thoughts.events` |

### AI / Embedding Model

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENSHIFT_AI_ENDPOINT_URL` | Base URL of the OpenAI-compatible embedding API | `http://localhost:65247/v1` |
| `OPENSHIFT_AI_API_KEY` | API key for the embedding endpoint | `dummy-key` |
| `EMBEDDING_MODEL_NAME` | Model name to request | `nomic-embed-text` |

### Evaluation

| Variable | Description | Default |
|----------|-------------|---------|
| `EVALUATION_SIMILARITY_THRESHOLD` | Cosine similarity threshold above which a thought is rejected | `0.85` |

## Running the Embedding Model

The evaluation service requires an OpenAI-compatible embedding endpoint. The default model is **nomic-embed-text**, and the dev profile expects it at `http://localhost:65247/v1`. The easiest way to run this locally is with [Ollama](https://ollama.com/).

### 1. Install Ollama

- **macOS:** `brew install ollama` or download from [ollama.com](https://ollama.com/)
- **Linux:** `curl -fsSL https://ollama.ai/install.sh | sh`

### 2. Pull the embedding model

```bash
ollama pull nomic-embed-text
```

### 3. Start Ollama with an OpenAI-compatible endpoint

Ollama natively exposes an OpenAI-compatible API. Start the server:

```bash
ollama serve
```

By default Ollama listens on port **11434**. The evaluation service dev profile expects port **65247**, so either:

**Option A** — Set the `OLLAMA_HOST` environment variable before starting Ollama:

```bash
OLLAMA_HOST=0.0.0.0:65247 ollama serve
```

**Option B** — Override the endpoint URL when running the Quarkus service:

```bash
OPENSHIFT_AI_ENDPOINT_URL=http://localhost:11434/v1 ./mvnw compile quarkus:dev
```

### 4. Verify the model is available

```bash
curl http://localhost:65247/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "nomic-embed-text", "input": "Hello world"}'
```

You should receive a JSON response containing an embedding vector.

### 5. Initialize the reference vectors

Once the service and model are running, seed the evaluation vectors with real embeddings:

```bash
curl -X POST http://localhost:8088/vectors/initialize -H 'Content-Type: application/json'
```

This replaces the placeholder vectors from the Flyway migration with actual embeddings generated by `nomic-embed-text`.

### Using a different model

You can use any OpenAI-compatible embedding model by setting these environment variables:

```bash
export EMBEDDING_MODEL_NAME=mxbai-embed-large    # or any model Ollama supports
export OPENSHIFT_AI_ENDPOINT_URL=http://localhost:11434/v1
```

If using OpenShift AI or another remote endpoint in production, set `OPENSHIFT_AI_ENDPOINT_URL` and `OPENSHIFT_AI_API_KEY` accordingly.

## Running the Application

### Development Mode

```bash
./mvnw compile quarkus:dev
```

Quarkus Dev Services will automatically start PostgreSQL and Kafka containers. The service listens on port **8088**.

### Production Mode

```bash
./mvnw package
java -jar target/quarkus-app/quarkus-run.jar
```

### Running Tests

```bash
./mvnw test
```

## API Endpoints

### REST API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/evaluations` | List evaluations (paginated: `?page=0&size=20`) |
| `GET` | `/evaluations/thought/{thoughtId}` | Get evaluation for a specific thought |
| `GET` | `/evaluations/stats` | Evaluation statistics (counts, average score) |
| `GET` | `/vectors/status` | Current vector database status (counts by type) |
| `POST` | `/vectors/initialize` | Delete all vectors and re-seed with real AI embeddings |

#### Initialize the Vector Database

```bash
curl -X POST http://localhost:8088/vectors/initialize -H 'Content-Type: application/json'
```

### Web UI (Qute)

| Path | Description |
|------|-------------|
| `/ui/evaluations` | Evaluations table |
| `/ui/evaluations/stats` | Statistics dashboard |

### Health and Metrics

| Path | Description |
|------|-------------|
| `/q/health/live` | Liveness probe |
| `/q/health/ready` | Readiness probe |
| `/q/metrics` | Prometheus metrics |

## Database Schema

Managed by Flyway migrations in `src/main/resources/db/migration/`:

- **V1** — `evaluation_vectors`: stores reference embedding vectors with type (POSITIVE/NEGATIVE) and label
- **V2** — `thought_evaluations`: stores per-thought evaluation results (status, similarity score, timestamps)
- **V3** — Seeds the initial 6 reference vectors with placeholder embedding data

## Tech Stack

- Quarkus 3.31.2
- Java 25
- Langchain4j (quarkus-langchain4j-openai) for embedding generation
- PostgreSQL with Hibernate ORM Panache
- Apache Kafka with SmallRye Reactive Messaging
- Qute templating for web UI
- SmallRye Fault Tolerance (retry logic on embedding calls)
- Micrometer with Prometheus for observability
- Deployed on Red Hat OpenShift
