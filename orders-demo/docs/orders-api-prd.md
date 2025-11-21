# Orders API Product Requirements

## 1. Goal & Context
- Provide a public-facing REST API that receives order events from demo clients and publishes them to the Strimzi-managed Kafka cluster (Phase 1), then extends to Azure Event Hubs in Phase 2 (Session 6 of the series).
- Showcase GitHub Copilot-driven development, containerization, and AKS deployment patterns during the livestream series.
- Serve as the source of truth for order creation, status lookup, and replay scenarios in the Orders Demo architecture.
- Demonstrate end-to-end observability by instrumenting the API with OpenTelemetry exporters for traces, metrics, and logs that surface in Azure Monitor/Grafana dashboards.

## 2. Success Criteria
- API receives ≥100 requests/second in load tests without error or noticeable latency increase.
- 99% of requests complete in <250 ms at P95 latency while targeting Kafka (Phase 1) and stay <300 ms once Event Hub support lands.
- Every accepted order results in exactly one message written to the active backend with traceable metadata.
- Live dashboards/GitHub Actions logs clearly show traffic flowing end-to-end during demos.
- OpenTelemetry traces and metrics from orders-api and orders-worker are correlated in a shared dashboard within 60 seconds of emission.

## 3. In Scope
- CRUD-style endpoints for orders (create, update status, retrieve, list recent).
- Kafka-first publisher implementation using the Strimzi Kafka cluster deployed in AKS, including SASL/PLAIN dev secrets and TLS config.
- Event Hub integration planned as a later milestone (Phase 2) reusing the same publisher abstraction interface.
- Basic schema validation, idempotency token handling, and lightweight auth (API key header) for demo purposes.
- Health and readiness endpoints for AKS/KEDA probes.
- OpenTelemetry instrumentation (FastAPI auto-instrumentation + custom spans/metrics) with OTLP exporters configurable via Helm.

### Out of Scope
- Payment processing or downstream fulfillment logic.
- Persistent database storage (orders are stored as messages only).
- Full-fledged auth (OAuth/JWT). API key header is sufficient for the demo.
- Multi-tenancy features beyond a simple `tenantId` attribute.

## 4. Key Personas & Use Cases
- **Demo Operator**: Runs load tests (`hey`, `locust`) to generate traffic during streams.
- **Viewer/Developer**: Clones repo, runs API locally, and inspects how Copilot helped scaffold FastAPI endpoints.
- **Observability Lead**: Verifies logs/metrics showing Kafka enqueue success/failure in Phase 1 and Event Hub results in Phase 2.

## 5. Functional Requirements
1. **Create Order** (`POST /orders`)
	- Accepts JSON payload with `orderId`, `customerId`, `items[]`, `totalAmount`, `tenantId`, `channel`.
	- Generates UUID when `orderId` absent.
	- Publishes message payload plus metadata (timestamp, requestId, auth principal) to the configured Kafka topic; when Event Hub support ships, the same abstraction routes to the namespace/hub.
	- Returns 202 with tracking info.
2. **Update Order Status** (`PATCH /orders/{orderId}`)
	- Fields: `status`, optional `notes`.
	- Publishes state-change event.
3. **Get Order** (`GET /orders/{orderId}`)
	- Retrieves latest cached result from in-memory store (for demo) or returns 404.
4. **List Orders** (`GET /orders?limit=50&tenantId=`)
	- Returns recent orders held in process cache for visualization.
5. **Health** (`GET /healthz`, `GET /readyz`)
	- Health returns 200 if service running.
	- Readiness checks connectivity to backend on startup.
6. **Admin Toggle** (`POST /admin/backend-mode`)
	- Introduced in Phase 2 to switch between Kafka and Event Hubs without redeploy by updating config map + secret.

### Validation & Error Handling
- Enforce required fields with Pydantic models; respond 422 on validation failures.
- Return 503 when publisher cannot connect to backend; include `retryAfter` hint.
- Idempotency header (`X-Request-Id`) ensures duplicate POSTs do not write duplicate messages.

## 6. Non-Functional Requirements
- **Performance**: Sustain 100 RPS on 0.5 vCPU pod; autoscale via KEDA when CPU >70% (Phase 1) and later add KEDA Kafka/Event Hub backlog scalers.
- **Reliability**: Retry publish failures (3 attempts, exponential backoff). Log dead-letter scenarios for worker replay demonstration.
- **Security**: API key required; secrets managed via Kubernetes Secret mounted as env var. Kafka credentials stored in Secret (username/password) initially; Managed Identity only needed once Event Hubs integration arrives.
- **Observability**: Emit structured logs (JSON) with `requestId`, `orderId`; instrument traces/metrics via OpenTelemetry SDK with OTLP exporters, defaulting to Azure Monitor or self-hosted Grafana Tempo/Loki stack.

## 7. External Dependencies
- Strimzi Kafka deployment inside AKS (required for Phase 1), including bootstrap service, topic, and user credentials.
- Azure Event Hubs namespace + event hub (Phase 2) for showcasing cloud-native messaging once Kafka path is stable.
- Azure Storage account for Event Hub checkpointing (shared with worker, needed Phase 2).

## 8. Configuration & Deployment
- Config via environment variables (Phase 1): `KAFKA_BROKERS`, `KAFKA_TOPIC`, `KAFKA_USERNAME`, `KAFKA_PASSWORD`, `API_KEY`. Additional vars (`BACKEND_MODE`, `EVENTHUB_NAMESPACE`, etc.) land in Phase 2.
- Helm chart templating for Deployment, Service, HPA/KEDA ScaledObject.
- CI/CD: GitHub Actions `build-api.yml` builds/pushes image; `deploy.yml` applies Helm release to AKS.

## 9. Metrics & Telemetry
- OpenTelemetry SDK auto-instrumentation for FastAPI/Uvicorn plus custom spans around Kafka/Event Hub publish calls.
- OTLP exporters configured via env/Helm values pointing at Azure Monitor (Application Insights) or the demo Grafana/Tempo stack.
- Prometheus metrics surfaced via OpenTelemetry metric pipeline: request counts, publish latency histogram, failure counts, cache depth gauge.
- Log correlation using OpenTelemetry logging integration so `requestId` ties logs to traces.

## 10. Risks & Mitigations
- **Kafka cluster unavailable**: Provide local fallback mock publisher for demos without Strimzi running; document bootstrap steps.
- **Schema drift**: Define JSON schema version field; worker validates version.
- **Secrets leakage**: Ensure `.env` excluded; provide `.env.sample` with guidance.
- **Phase split confusion**: README + PRDs must call out that Event Hub support is scheduled for Session 6 to set viewer expectations.

## 11. Milestones
1. Scaffold FastAPI project + request models (Session 2).
2. Implement Kafka publisher + unit tests for serialization (Session 2/3).
3. Build worker-facing contract docs + local Strimzi testing (Session 3).
4. Containerize + Helm deploy both services (Session 4).
5. Wire CI/CD pipelines (Session 5).
6. Add Event Hub publisher + backend toggle + Managed Identity auth (Session 6).
7. Introduce Event Hub/KEDA scaler demo + documentation updates (Session 6).

## 12. Open Questions
- Do we need pagination for `GET /orders` beyond query params? (Probably not for demo.)
- Should we persist orders to Cosmos DB for historical demos later?
- What default load generator will we showcase (hey vs. custom script)?
- How do we present backend switch during the stream (live toggle vs. redeploy)?