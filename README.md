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
1. AI-Assisted Development with GitHub Copilot
* Code generation from PRDs
* Scaffolding FastAPI apps
* Creating Dockerfiles & Helm charts
* Accelerating Kubernetes configuration
2. Event-Driven Architecture
* Producers and consumers
* Kafka and Event Hub dual-mode backend
* Consumer groups and checkpointing
* Message publication and processing patterns
3. Kubernetes on Azure
* Deploying microservices with Helm
* Configuring Deployments, Services, and Ingress
* Using Managed Identities with AKS
* Integrating with ACR
4. Autoscaling with KEDA
* Event-Hub-backlog-based autoscaling
* Scale from 0 → N worker replicas
* Real-time processing demos
5. CI/CD with GitHub Actions
* Build → Scan → Push → Deploy
* ACR authentication
* Automatic Helm releases
* Environment separation
6. Infrastructure as Code (Bicep)
* AKS cluster
* Event Hub namespace + Event Hub
* Storage account for checkpoints
* ACR + Managed Identities + RBAC
* Modularized Bicep design
7. (Optional) Multi-Cluster with AKS Fleet Manager
* Workload propagation
* Multi-region deployments
* Shared Event Hub backbone
* Cluster-aware autoscaling
---
## 📚 Repository Structure
```
orders-demo/
│
├── docs/
│   ├── orders-api-prd.md
│   └── orders-worker-prd.md
│
├── infra/
│   ├── main.bicep
│   └── modules/
│       ├── acr.bicep
│       ├── aks.bicep
│       ├── eventhubs.bicep
│       ├── storage.bicep
│       ├── identity.bicep
│       └── roles.bicep
│
├── services/
│   ├── orders-api/
│   │   ├── app/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── orders-worker/
│       ├── app/
│       ├── Dockerfile
│       └── requirements.txt
│
├── charts/
│   ├── orders-api/
│   └── orders-worker/
│
└── .github/
    └── workflows/
        ├── build-api.yml
        ├── build-worker.yml
        └── deploy.yml
```

## 🌐 Environment & Prerequisites
### Azure Resources the Demo Uses
| Resource	| Purpose|
| ----------- | ----------- |
|AKS	| Runs the microservices |
|ACR	| Stores Docker images |
|Event Hubs	| Messaging backend (primary) |
|Kafka (Strimzi)	| Optional in-cluster Kafka |
|Storage Account	| Event Hub checkpointing |
|Managed Identity	| Secure broker access |
|KEDA	| Event-driven autoscaling |

All resources are provisioned using the Bicep files under /infra.

**Tools Required**
* Azure CLI
* kubectl
* Helm
* Docker
* GitHub CLI (optional)
* VS Code + GitHub Copilot

## 📺 Livestream / YouTube Series Curriculum

This repository is designed to accompany a multi-part technical series.

### Session 1 — Architecture + Environment Build + Repo Bootstrap
* Overview of event-driven architecture
* Deploy AKS + Event Hubs + Storage + MI using Bicep
* Repo structure & PRDs

### Session 2 — Build orders-api with GitHub Copilot
* FastAPI + event producer
* Dual-mode backend support
* Local testing

### Session 3 — Build orders-worker with GitHub Copilot
* Event consumer loop
* Checkpointing & metrics
* Test against Event Hubs

### Session 4 — Containerization + Helm Charts
* Dockerfiles
* Deploy both services to AKS with Helm

### Session 5 — CI/CD with GitHub Actions
* Build pipelines
* Deploy pipelines
* ACR integration

### Session 6 — Event Hub Integration + KEDA Autoscaling
* Event Hub consumer group
* KEDA ScaledObject
* Live autoscale demo

### Session 7 (Optional) — AKS Fleet Manager
* Multi-cluster deployment
* Shared Event Hub backbone
* Global autoscaling

## 🧪 Running the Demo
1. Deploy the infrastructur
```
az deployment sub create \
  --name orders-demo \
  --location <region> \
  --template-file infra/main.bicep \
  --parameters environmentName=dev
```
2. Get AKS credentials
```
az aks get-credentials \
  -g <resource-group> \
  -n <aks-name>
```
3. Deploy the services with Helm
```
helm upgrade --install orders-api ./charts/orders-api
helm upgrade --install orders-worker ./charts/orders-worker
```
4. Generate load
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

⭐ Acknowledgements

This project highlights Azure + GitHub working together across:
* Developer productivity
* DevOps automation
* Kubernetes operations
* Cloud-native architectures
* Event-driven scaling

Thanks to all participants in building and reviewing this demo!
