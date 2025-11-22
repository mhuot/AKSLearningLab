PYTHON ?= python3
API_DIR := services/orders-api
WORKER_DIR := services/orders-worker
CHARTS_DIR := charts
IMAGE_REGISTRY ?= ghcr.io/demo

INFRA_MAIN := infra/main.bicep
INFRA_PARAMETERS ?= infra/parameters.dev.json
DEPLOYMENT_NAME ?= orders-demo
DEPLOYMENT_LOCATION ?= eastus
AZ_SUBSCRIPTION ?=
AZ_SUBSCRIPTION_FLAG :=
ifneq ($(strip $(AZ_SUBSCRIPTION)),)
AZ_SUBSCRIPTION_FLAG := --subscription $(AZ_SUBSCRIPTION)
endif
SSH_PUBLIC_KEY_PATH ?= $(HOME)/.ssh/id_rsa.pub
SSH_PUBLIC_KEY := $(shell test -f "$(SSH_PUBLIC_KEY_PATH)" && cat "$(SSH_PUBLIC_KEY_PATH)" || echo "")
GENERATED_DIR := deploy/generated
INFRA_OUTPUTS := $(GENERATED_DIR)/infra-outputs.json
HELM_API_VALUES_FILE ?= $(GENERATED_DIR)/orders-api.values.generated.yaml
HELM_WORKER_VALUES_FILE ?= $(GENERATED_DIR)/orders-worker.values.generated.yaml

.PHONY: help lint lint-api lint-worker build build-api build-worker docker docker-api docker-worker deploy helm-install helm-upgrade ci-local infra-deploy helm-values clean-generated

help:
	@echo "Available targets:"
	@echo "  lint           - run lint for api + worker"
	@echo "  build          - package Helm charts"
	@echo "  docker         - build local Docker images"
	@echo "  deploy         - helm upgrade --install both services"
	@echo "  ci-local       - run GitHub Actions workflows via act"
	@echo "  infra-deploy   - run Bicep deployment and capture outputs"
	@echo "  helm-values    - convert infra outputs into Helm overrides"

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

$(GENERATED_DIR):
	mkdir -p $@


define CHECK_SSH_KEY
if [ -z "$(SSH_PUBLIC_KEY)" ]; then \
  echo "SSH public key not found at $(SSH_PUBLIC_KEY_PATH). Set SSH_PUBLIC_KEY_PATH or create a key."; \
  exit 1; \
fi
endef

$(INFRA_OUTPUTS): $(INFRA_MAIN) $(INFRA_PARAMETERS) | $(GENERATED_DIR)
	@$(CHECK_SSH_KEY)
	az deployment sub create \
		$(AZ_SUBSCRIPTION_FLAG) \
		--name $(DEPLOYMENT_NAME) \
		--location $(DEPLOYMENT_LOCATION) \
		--template-file $(INFRA_MAIN) \
		--parameters @$(INFRA_PARAMETERS) sshRSAPublicKey="$(SSH_PUBLIC_KEY)"
	az deployment sub show \
		$(AZ_SUBSCRIPTION_FLAG) \
		--name $(DEPLOYMENT_NAME) \
		--query properties.outputs \
		--output json > $@

infra-deploy: $(INFRA_OUTPUTS)

helm-values: $(INFRA_OUTPUTS)
	@echo "Generating Helm overrides from $(INFRA_OUTPUTS)"
	@$(PYTHON) deploy/render_helm_values.py \
		--outputs $(INFRA_OUTPUTS) \
		--api-values $(HELM_API_VALUES_FILE) \
		--worker-values $(HELM_WORKER_VALUES_FILE)

helm-install:
	helm install orders-api $(CHARTS_DIR)/orders-api || true
	helm install orders-worker $(CHARTS_DIR)/orders-worker || true

helm-upgrade:
	@if [ -f $(HELM_API_VALUES_FILE) ]; then \
		API_OVERRIDES="-f $(HELM_API_VALUES_FILE)"; \
	else \
		API_OVERRIDES=""; \
	fi; \
	helm upgrade --install orders-api $(CHARTS_DIR)/orders-api $$API_OVERRIDES
	@if [ -f $(HELM_WORKER_VALUES_FILE) ]; then \
		WORKER_OVERRIDES="-f $(HELM_WORKER_VALUES_FILE)"; \
	else \
		WORKER_OVERRIDES=""; \
	fi; \
	helm upgrade --install orders-worker $(CHARTS_DIR)/orders-worker $$WORKER_OVERRIDES

deploy: docker helm-values helm-upgrade

ci-local:
	act -W .github/workflows/build-api.yml -j build || true
	act -W .github/workflows/build-worker.yml -j build || true

clean-generated:
	rm -rf $(GENERATED_DIR)
