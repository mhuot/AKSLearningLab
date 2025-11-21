# Orders Demo Workspace

This folder contains the end-to-end AKS Orders Demo referenced in the [root README](../README.md). It hosts docs, infrastructure-as-code, services, Helm charts, and GitHub Actions workflows so streams can focus on iterating instead of bootstrapping.

## Repository Layout
- `docs/`: Product requirements and design notes for `orders-api` and `orders-worker`.
- `infra/`: Bicep entry point plus modules for AKS, Strimzi Kafka, Event Hubs, ACR, storage, identities, and future Azure Monitor resources.
- `services/`: FastAPI producer (`orders-api`) and Python worker skeletons with Dockerfiles and requirements files.
- `charts/`: Helm charts that will deploy each service with configurable environment variables (including OTLP exporters once wired up).
- `.github/workflows/`: Build/deploy pipelines used during the livestream series.

## Local Development (Preview)
1. Create and activate a Python 3.11 virtual environment.
2. Install API/worker requirements (`pip install -r services/orders-api/requirements.txt`, etc.).
3. Run `uvicorn services.orders-api.app.main:app --reload` (after main module exists) to test locally.
4. Use `docker build -t orders-api:dev services/orders-api` as a container sanity check.
5. Point OpenTelemetry env vars (e.g., `OTEL_EXPORTER_OTLP_ENDPOINT`) at your Azure Monitor ingestion endpoint or local collector before running.

### Makefile Shortcuts
The repo ships with a `Makefile` inside this folder to reduce copy/paste during the livestream:
- `make lint` — placeholder lint pass for API + worker.
- `make build` — packages both Helm charts.
- `make docker` — builds local images tagged with `IMAGE_REGISTRY` (default `ghcr.io/demo`).
- `make deploy` — runs Docker builds then `helm upgrade` for both services.
- `make ci-local` — runs GitHub Actions workflows locally via `act` (requires Docker + [`act`](https://github.com/nektos/act)).

Set `IMAGE_REGISTRY`, `OTEL_EXPORTER_OTLP_ENDPOINT`, and other env vars via `.env` or shell before running targets.

## Stream Agenda Snapshot
- **Session 1**: Provision AKS, Storage, Managed Identity, and Application Insights via Bicep while walking through these folders.
- **Session 2**: Build the FastAPI producer with Kafka-first publishing and OTel instrumentation.
- **Session 3**: Implement the worker, wire Kafka consumers, and integrate telemetry.
- **Session 4**: Finalize Dockerfiles + Helm charts and configure OTLP endpoints through values files.
- **Session 5**: Hook up CI/CD workflows in `.github/workflows/` to build/push/deploy.
- **Session 6**: Add Azure Event Hub + KEDA autoscaling, demonstrate traces/metrics flowing into Azure Monitor dashboards.

Refer to the [root README](../README.md) for the complete curriculum, prerequisites, and detailed instructions.
