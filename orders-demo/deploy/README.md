# Deployment Artifacts

This folder keeps human-authored deployment helpers while ignoring any generated files:

- `generated/` *(gitignored)* — holds `infra-outputs.json` plus Helm override files that get produced by `make helm-values`. You can delete this directory safely at any time.
- `README.md` — the document you are reading now.

## Workflow Summary
1. Deploy infrastructure with `make infra-deploy` (or any target that depends on it). This runs the Bicep template and captures outputs as JSON under `deploy/generated/infra-outputs.json`.
2. Produce Helm override files with `make helm-values`. This reads the JSON outputs and emits:
   - `orders-api.values.generated.yaml`
   - `orders-worker.values.generated.yaml`
3. Apply the services via `make helm-upgrade` (or `make deploy`) to feed those overrides to Helm automatically.

If you prefer to provide your own values, drop files into `deploy/generated/` (or point `HELM_*_VALUES_FILE` variables at another path) before running the Helm targets.
