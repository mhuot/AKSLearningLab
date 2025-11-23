# Orders Demo — Event-Driven Microservices on AKS
### AKS · Event Hubs · Kafka · KEDA · GitHub Actions · GitHub Copilot

This repository contains a complete, end-to-end demonstration of building, deploying, and scaling cloud-native microservices on Azure Kubernetes Service (AKS). The project showcases how GitHub Copilot, Azure Event Hubs, Kafka, KEDA, and GitHub Actions come together to deliver a modern, scalable, event-driven architecture.

## Overview

The demo consists of two microservices:

| Service | Description | Tech Highlights |
|---------|-------------|------------------|
| orders-api | Receives incoming order requests and publishes them to a messaging backend (Event Hubs or Kafka) | FastAPI, Gunicorn, Kafka client, Azure Event Hub SDK |
| orders-worker | Consumes and processes order events; horizontally autoscaled via KEDA based on backlog | Python worker, EventHub/Kafka consumers, KEDA autoscaler |

## Architecture

```mermaid
graph TD
    Client([Client / Load Generator]) -->|POST /orders| Ingress[Ingress Controller]
    
    subgraph Azure_Cloud [Azure Cloud]
        ACR[Azure Container Registry]
        Monitor[Azure Monitor / App Insights]
        
        subgraph AKS_Cluster [AKS Cluster]
            Ingress --> API[orders-api Service]
            
            subgraph Pods
                API_Pod[orders-api Pod]
                Worker_Pod[orders-worker Pod]
            end
            
            API --> API_Pod
            
            %% Dual Backend Representation
            API_Pod -->|Publish Event| Broker{Message Broker}
            
            subgraph Messaging [Event Backbone]
                Broker -.->|Option A| Kafka[Strimzi Kafka]
                Broker -.->|Option B| EH[Azure Event Hubs]
            end
            
            Kafka -->|Consume| Worker_Pod
            EH -->|Consume| Worker_Pod
        end
    end

    %% CI/CD Link
    ACR -.->|Pull Image| API_Pod
    ACR -.->|Pull Image| Worker_Pod
    
    %% Observability Links
    API_Pod -.->|OTLP Traces/Metrics| Monitor
    Worker_Pod -.->|OTLP Traces/Metrics| Monitor

    %% Accessible color theme (WCAG-compliant contrast)
    classDef ingress fill:#005A9C,stroke:#002C52,color:#FFFFFF,font-weight:bold;
    classDef control fill:#0063B1,stroke:#002C52,color:#FFFFFF;
    classDef workload fill:#0078D4,stroke:#004578,color:#FFFFFF;
    classDef broker fill:#107C10,stroke:#0B5C0B,color:#FFFFFF;
    classDef observability fill:#8A2DA5,stroke:#4C1A68,color:#FFFFFF;
    classDef registry fill:#5C2D91,stroke:#32145A,color:#FFFFFF;

    class Ingress ingress;
    class API,API_Pod,Worker_Pod workload;
    class Broker,Kafka,EH broker;
    class Monitor observability;
    class ACR registry;
    class Client control;
```

Legend:
- **Blue (control/workloads)** — AKS ingress + services handling HTTP traffic.
- **Green (broker)** — Messaging backbones (Strimzi Kafka, Azure Event Hubs).
- **Purple (registry/observability)** — ACR and Azure Monitor/App Insights integrations.
- **Solid arrows** — Primary request/publish/consume paths.
- **Dashed arrows** — Optional or alternative flows (Kafka vs. Event Hub) and image pulls.
- **Dotted arrows** — Telemetry exports (OTLP traces/metrics) heading to Azure Monitor.

```
Client
    ↓ POST /orders
orders-api (FastAPI)
    ↓ publish
Event Hub / Kafka
    ↓ consume
orders-worker (Python worker)
    ↓
Processing, metrics, logs
```

## 🎯 Skills Demonstrated
1. **Copilot-assisted application scaffolding**
    - Code generation from PRDs and architectural briefs
    - Scaffolding FastAPI services, Dockerfiles, and Helm charts
    - Accelerating Kubernetes configuration through reusable manifests
2. **Event-driven architecture**
    - Designing producers/consumers with Kafka _and_ Azure Event Hubs
    - Managing consumer groups, checkpointing, and dual-mode backends
    - Demonstrating publish/consume patterns for real-time orders traffic
3. **Kubernetes on Azure**
    - Deploying microservices with Helm and GitOps-style overrides
    - Configuring Deployments, Services, Ingress, and managed identities
    - Integrating AKS with ACR and other Azure control-plane resources
4. **Autoscaling with KEDA**
    - Event Hub backlog-driven scale-up/scale-down workflows
    - Scaling workers from 0 → N replicas for cost efficiency
    - Live demos tying traffic to scaling behavior
5. **Observability with OpenTelemetry**
    - Instrumenting FastAPI + worker services for traces/metrics/logs
    - Exporting OTLP data into Azure Monitor and Grafana dashboards
    - Correlating KEDA decisions with application telemetry
6. **CI/CD with GitHub Actions**
    - Build → scan → push → deploy workflows targeting ACR/AKS
    - Secure ACR authentication and automated Helm releases
    - Environment separation for dev/demo vs. future stages
7. **Infrastructure as Code (Bicep)**
    - Provisioning AKS, Event Hubs, storage, identities, and RBAC
    - Modularized Bicep design tuned for demos and reproducibility
8. **(Optional) AKS Fleet Manager**
    - Multi-cluster propagation, shared Event Hub backbones
    - Multi-region rollouts and cluster-aware autoscaling experiments
---
## 📚 Repository Structure
- Top-level code lives under `orders-demo/`. That workspace contains the infra modules, services, Helm charts, docs, and GitHub Actions workflows.
- For a folder-by-folder breakdown, local dev tips, and Makefile notes, jump to `orders-demo/README.md`. This root doc stays oriented on architecture, prerequisites, and how to run the full demo.

## 🗂️ Documentation Guide
- `README.md` (this file) covers the big picture: why the demo exists, architectural context, prerequisites, and the end-to-end deployment/runbook.
- `orders-demo/README.md` captures workspace internals—detailed folder descriptions, Make targets, local dev steps, and the session-by-session agenda.

## 🌐 Environment & Prerequisites
### Azure Resources the Demo Uses
|Resource	| Purpose|
| ----------- | ----------- |
|AKS	| Runs the microservices |
|ACR	| Stores Docker images |
|Event Hubs	| Messaging backend (phase 2) |
|Kafka (Strimzi)	| Primary in-cluster Kafka (phase 1) |
|Storage Account	| Event Hub checkpointing |
|Managed Identity	| Secure broker access |
|KEDA	| Event-driven autoscaling |
|Azure Monitor + Application Insights| Collects OpenTelemetry traces/metrics/logs via OTLP ingestion |

> Storage accounts are globally unique. By default the Bicep template now appends a deterministic suffix to the `storageAccountPrefix` value (see `infra/parameters.dev.json`) so every environment gets its own valid name. Set `storageAccountRandomize` to `false` and provide `storageAccountName` if you need to pin a specific name.

### Choosing Regions & AKS Versions
- Update `infra/parameters.<env>.json` and/or export `DEPLOYMENT_LOCATION` before running `make infra-deploy` so resources land in the region you intend to demo from.
- AKS only supports a subset of Kubernetes versions per region. Always verify the available versions before deploying:
    ```bash
    az aks get-versions --location <region> --output table
    ```
    Copy a non-preview version (for example `1.33.5` in `northcentralus`) into the `kubernetesVersion` parameter if the default is not available.
- If you switch regions later, rerun the command above for the new region and update the parameter or pass `-p kubernetesVersion=<version>` when invoking `az deployment`/`make infra-deploy`.
- The default AKS system pool uses the `Standard_D2as_v5` VM size (8 cores total for two nodes). If your subscription shows `QuotaExceeded` for that SKU in the chosen region, either request more cores via the Azure Portal (`Usage + quotas` → `standardDASv5Family`) or override `agentPoolVmSize`/`agentPoolNodeCount` in `infra/parameters.<env>.json` to a SKU you already have capacity for.

All resources are provisioned using the Bicep files under /infra.

**Tools Required**
* Azure CLI
* kubectl
* Helm
* Docker
* [act](https://github.com/nektos/act) (for local GitHub Actions runs)
* GitHub CLI (optional)
* VS Code + GitHub Copilot
> All of the Make targets (`infra-deploy`, `helm-values`, `deploy`, etc.) live inside `orders-demo/`. `cd orders-demo` before running the commands below so the Makefile and generated files resolve correctly.

## 📺 Livestream / YouTube Series Curriculum

A six-part livestream (plus an optional Fleet Manager add-on) walks through the journey: bootstrap the Azure environment, build the producer and worker, containerize + deploy with Helm, wire up CI/CD, and finish with Event Hub + KEDA autoscaling. For the detailed agenda, session checklists, and speaker notes, see `orders-demo/README.md`.

## 🧪 Running the Demo

1. Deploy the infrastructure (using the provided dev parameters file)

```bash
az deployment sub create \
    --name orders-demo \
    --location <region> \
    --template-file infra/main.bicep \
    --parameters @infra/parameters.dev.json
```

_Shortcut_: Run `make infra-deploy` from `orders-demo/` to execute the same deployment and capture its outputs under `deploy/generated/infra-outputs.json`.

_SSH key_: `make infra-deploy` looks for a public key at `~/.ssh/id_rsa.pub`. Override this path with `SSH_PUBLIC_KEY_PATH=~/.ssh/orders-demo.pub make infra-deploy` or create a key with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/orders-demo`.

_One-time provider registration (required before your first infra deploy in a subscription; skip if you’ve already run it in this tenant):_

```bash
az provider register --namespace Microsoft.OperationsManagement --wait
az provider register --namespace Microsoft.OperationalInsights --wait
```

_Role assignments_: If you ever see `RoleDefinitionDoesNotExist`, rerun:

```bash
az role definition list --name "Azure Event Hubs Data Sender" --query "[0].name" -o tsv
```

Compare the GUID output with the value in `orders-demo/infra/modules/roles.bicep` (repeat for the other role names listed there). Update the file if Microsoft publishes new IDs before deploying again.

2. Get AKS credentials
```
az aks get-credentials \
  -g <resource-group> \
  -n <aks-name>
```

Run this right after the infrastructure deploy (add `--overwrite-existing` if needed). If `helm` ever says `kubernetes cluster unreachable` or tries to talk to `localhost:8080`, it means this step was skipped or pointed at the wrong cluster.

3. Convert the captured outputs into Helm overrides
```
make helm-values
```

This creates `deploy/generated/orders-api.values.generated.yaml` and `deploy/generated/orders-worker.values.generated.yaml`, pre-populated with the actual Event Hub namespace, storage account, and Application Insights connection string from Azure.

4. Deploy the services with Helm (the `make deploy` target chains docker builds → `helm-values` → Helm releases)
```
make deploy
```

Common gotchas:
- Install Helm locally (`brew install helm`) before running any Make targets that render charts.
- Re-run `az aks get-credentials` if you rotated clusters or kubeconfig entries; Helm needs an active context that points at the AKS control plane.
- After `make infra-deploy` succeeds, the Makefile reads the emitted `acrLoginServer` and automatically tags images as `<your-acr>.azurecr.io/...`. For alternate registries, override with `IMAGE_REGISTRY=<registry> make deploy`.
- The Helm upgrade now receives `--set image.repository=<registry>/orders-{api,worker}` and `--set image.tag=dev` automatically, so you do not need to edit the charts to change image names.
- Docker builds default to `linux/amd64` (via `DOCKER_DEFAULT_PLATFORM`) so images run on AKS nodes. Override with `DOCKER_DEFAULT_PLATFORM=linux/arm64 make deploy` only if your cluster is arm64.

5. Push the images to ACR so AKS can pull them (you must authenticate first)
```
az acr login -n ordersacrdev   # replace with your ACR name
make push
```
`make push` simply runs `docker push` for both tags using the same `IMAGE_REGISTRY`. If you prefer manual commands, run `docker push <registry>/orders-api:dev` and `docker push <registry>/orders-worker:dev` right after `make deploy` completes. If Docker ever returns `unauthorized`, re-run `az acr login -n <your-acr>` in the same shell and rerun the pushes.

6. Generate load
```
hey -z 30s -q 10 https://<api-endpoint>/orders
```

Watch KEDA scale out:
```
kubectl get pods -w
```

## 🙋 Contributing

Contributions are welcome!
Feel free to:
* File issues
* Submit PRs
* Suggest improvements or new demo scenarios

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE).

⭐ Acknowledgements

This project highlights Azure + GitHub working together across:
* Developer productivity
* DevOps automation
* Kubernetes operations
* Cloud-native architectures
* Event-driven scaling

Thanks to all participants in building and reviewing this demo!
