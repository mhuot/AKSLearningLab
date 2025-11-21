PYTHON ?= python3
API_DIR := services/orders-api
WORKER_DIR := services/orders-worker
CHARTS_DIR := charts
IMAGE_REGISTRY ?= ghcr.io/demo

.PHONY: help lint lint-api lint-worker build build-api build-worker docker docker-api docker-worker deploy helm-install helm-upgrade ci-local

help:
	@echo "Available targets:"
	@echo "  lint           - run lint for api + worker"
	@echo "  build          - package Helm charts"
	@echo "  docker         - build local Docker images"
	@echo "  deploy         - helm upgrade --install both services"
	@echo "  ci-local       - run GitHub Actions workflows via act"

lint: lint-api lint-worker

lint-api:
	cd $(API_DIR) && $(PYTHON) -m compileall app || true

lint-worker:
	cd $(WORKER_DIR) && $(PYTHON) -m compileall app || true

build: build-api build-worker

build-api:
	helm package $(CHARTS_DIR)/orders-api

build-worker:
	helm package $(CHARTS_DIR)/orders-worker

# Docker builds keep things consistent for demos.
docker: docker-api docker-worker

docker-api:
	docker build -t $(IMAGE_REGISTRY)/orders-api:dev $(API_DIR)

docker-worker:
	docker build -t $(IMAGE_REGISTRY)/orders-worker:dev $(WORKER_DIR)

helm-install:
	helm install orders-api $(CHARTS_DIR)/orders-api || true
	helm install orders-worker $(CHARTS_DIR)/orders-worker || true

helm-upgrade:
	helm upgrade orders-api $(CHARTS_DIR)/orders-api
	helm upgrade orders-worker $(CHARTS_DIR)/orders-worker

deploy: docker helm-upgrade

ci-local:
	act -W .github/workflows/build-api.yml -j build || true
	act -W .github/workflows/build-worker.yml -j build || true
