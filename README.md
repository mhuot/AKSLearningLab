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

## Skills Demonstrated

- AI-Assisted Development with GitHub Copilot
- Event-Driven Architecture
- Kubernetes on Azure
- Autoscaling with KEDA
- CI/CD with GitHub Actions
- Infrastructure as Code with Bicep
- Optional Multi-Cluster with AKS Fleet Manager

## Repository Structure

... (truncated for brevity; include full content in final version) ...
