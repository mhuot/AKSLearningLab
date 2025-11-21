# Orders Worker Product Requirements

## 1. Goal & Context
- Provide a Python-based worker that consumes order events from the Strimzi-managed Kafka cluster (Phase 1) and Azure Event Hubs (Phase 2), applying business logic, emitting metrics, and updating downstream systems.
- Demonstrate KEDA-driven autoscaling on AKS using both Kafka and Event Hub scalers.
- Showcase observability best practices by exporting traces, logs, and metrics via OpenTelemetry into Azure Monitor/Application Insights (with optional Grafana replicas).

## 2. Success Criteria
- Worker sustains 100 events/second in Kafka mode while maintaining <500 ms average processing latency under normal load.
- Autoscaling reacts to backlog within 60 seconds, scaling from 0 → N pods using KEDA triggers.
- OpenTelemetry traces and metrics from worker correlate with orders-api within Azure Monitor workbook dashboards.
- At-least-once processing semantics with idempotent handlers (retries do not double-process the same order).

## 3. In Scope
- Kafka consumer implementation with configurable consumer group, partition assignment, and offset checkpointing (Phase 1).
- Event Hub consumer port with Azure Storage checkpointing (Phase 2).
- Business logic stub: logging, status updates, optional HTTP callback to mimic fulfillment service.
- Structured logging, metrics counters (events processed, failures), and trace spans wrapping consumption and business logic.
- Health/readiness endpoints for AKS/KEDA probes.

### Out of Scope
- Durable storage of processed results (beyond log records / sample callbacks).
- Elaborate retry workflows or manual compensation UI.
- Multi-tenant scheduling beyond simple `tenantId` filtering.

## 4. Personas & Use Cases
- **Demo Operator**: Observes KEDA scaling while generating traffic.
- **Viewer/Developer**: Learns how GitHub Copilot helps scaffold consumer loops, KEDA configs, and telemetry.
- **SRE/Observability Engineer**: Verifies trace linkage between API and worker, monitors failure alerts.

## 5. Functional Requirements
1. **Kafka Consumer Loop**
	- Configurable topic, bootstrap servers, consumer group, and auth (SASL/PLAIN).
	- Batch size and poll interval configurable to demo tuning.
	- Manual commit after successful processing; retries on transient errors.
2. **Event Hub Consumer (Phase 2)**
	- Use Azure Event Hub Python SDK with Storage account checkpointing.
	- Share payload schema with Kafka path.
3. **Order Processing Handler**
	- Deserialize JSON, validate schema version, update status in log output, optionally call mock downstream API.
	- Emit events to logs/metrics for success, failure, retry.
4. **Health/Ready Endpoints**
	- `/healthz` returns 200 when process is alive.
	- `/readyz` ensures consumer is connected to backend.
5. **Admin Controls (Phase 2)**
	- Support toggling backend mode via env/config (Kafka vs Event Hub) without redeploy where possible.

### Error Handling
- Retries with exponential backoff for transient errors (configurable attempt count).
- Dead-letter/failure logging for messages that exceed retry limit.
- Idempotent processing enforced via `orderId`/`requestId` to avoid duplicates.

## 6. Non-Functional Requirements
- **Performance**: Handle 100 RPS steady state with 0.5 vCPU target; degrade gracefully beyond.
- **Scalability**: KEDA scales worker deployment using Kafka partition lag (Phase 1) and Event Hub consumer lag (Phase 2).
- **Reliability**: Built-in retry/backoff, manual trigger for reprocessing (kubectl exec command or admin API).
- **Security**: Secrets (Kafka password, Event Hub connection) stored in Kubernetes Secrets and injected as env vars; Managed Identity for Event Hub when in AKS.
- **Observability**: OpenTelemetry instrumentation for consumer loop, processing spans, metrics (events processed, backlog length), and logs forwarded to Azure Monitor/App Insights.

## 7. External Dependencies
- Strimzi Kafka deployment inside AKS with topic `orders` and service account credentials.
- Azure Event Hubs namespace + hub (Phase 2) and Azure Storage account for checkpoints.
- Azure Monitor workspace + Application Insights for telemetry ingestion.
- Optional mock downstream service for demonstrating post-processing.

## 8. Configuration & Deployment
- Config via env vars: `KAFKA_BROKERS`, `KAFKA_TOPIC`, `KAFKA_GROUP`, `KAFKA_USERNAME`, `KAFKA_PASSWORD`, `EVENTHUB_NAMESPACE`, `EVENTHUB_NAME`, `STORAGE_ACCOUNT`, `BACKEND_MODE`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES`, `POLL_INTERVAL`.
- Helm chart to set env vars, mount secrets, configure readiness/liveness probes, and KEDA ScaledObject specs.
- Deployment uses single container image built via GitHub Actions, referencing `orders-worker` chart.

## 9. Metrics & Telemetry
- Counters: `orders_processed_total`, `orders_failed_total`, `retries_total`.
- Gauges: `current_backlog` (if exposed through Kafka metrics), `worker_concurrency`.
- Histograms: `processing_duration_seconds`.
- Traces: span per message consumption and processing with `orderId` attributes.
- Logs: structured JSON with `tenantId`, `orderId`, `traceId`, `spanId` for easy correlation.

## 10. Risks & Mitigations
- **Kafka cluster downtime**: Provide local mock publisher/consumer for demos; document fallback.
- **Event Hub throttling**: Tune prefetch/poll parameters; include backoff instructions.
- **Telemetry overload**: Allow sampling/aggregation settings to avoid high ingestion cost.
- **Secrets handling**: Provide `.env.example` guidance and warn against committing real secrets.

## 11. Milestones
1. Implement Kafka consumer loop + unit tests (Session 3).
2. Add OpenTelemetry instrumentation and metrics exporters.
3. Containerize worker + Helm chart updates (Session 4).
4. Integrate KEDA scaler + autoscale demo (Session 6 alongside Event Hub integration).
5. Add Event Hub consumer implementation (Session 6).

## 12. Open Questions
- Do we need to persist results (e.g., Cosmos DB) for future sessions?
- Should we implement a UI or CLI to inspect worker progress during streams?
- How will we rotate secrets / service principals in the demo environment?
