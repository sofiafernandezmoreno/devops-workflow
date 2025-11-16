# ---------------------------------------------------------
# Load .env if present
# ---------------------------------------------------------
ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\s*\([A-Za-z_][A-Za-z0-9_]*\)\s*=.*/\1/p' .env)
endif

# ---------------------------------------------------------
# Default target: help
# ---------------------------------------------------------
.DEFAULT_GOAL := help

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------
APP_NAME  := nn-devops-challenge
APP_DIR   := app

# AWS / Registry
AWS_REGION     ?= eu-west-1
AWS_ACCOUNT_ID ?=
REGISTRY       ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG            ?= local
IMAGE          := $(REGISTRY)/$(APP_NAME):$(TAG)

IMAGE_REPOSITORY ?= $(REGISTRY)/$(APP_NAME)
IMAGE_TAG        ?= $(TAG)

# Terraform settings
TERRAFORM_DIR ?= infra
ENV           ?= dev
AWS_PROFILE   ?= terraform-nn-devops

TF_VARS_FILE  := $(TERRAFORM_DIR)/envs/$(ENV)/terraform.tfvars

# Helm / deploy
CHART_PATH    ?= helm
DEPLOY_SCRIPT ?= scripts/deploy.sh
CHART_ENVS_DIR            ?= $(CHART_PATH)/envs
# Helm chartsnap (snapshot testing)
CHART_SNAPSHOT_VALUES_DIR  ?= $(CHART_PATH)/ci
CHART_SNAPSHOT_OUTPUT_DIR ?= $(CHART_PATH)/ci/snapshots

IMAGE_REPOSITORY ?= $(REGISTRY)/$(APP_NAME)
IMAGE_TAG        ?= $(TAG)

# ---------------------------------------------------------
# COSIGN (local keys)
# ---------------------------------------------------------
COSIGN_KEY := cosign.cert/cosign.key
COSIGN_PUB := cosign.cert/cosign.pub

# ---------------------------------------------------------
# Image signing by digest
# ---------------------------------------------------------
IMAGE_DIGEST ?=
IMAGE_REF_BY_DIGEST := $(REGISTRY)/$(APP_NAME)@$(IMAGE_DIGEST)

# ---------------------------------------------------------
# Colors
# ---------------------------------------------------------
YELLOW := \033[1;33m
CYAN   := \033[1;36m
RESET  := \033[0m

# ---------------------------------------------------------
# Phony targets
# ---------------------------------------------------------
.PHONY: help \
        test run \
        build package \
        scan push login-ecr \
        cosign-install cosign-check sign verify sign-digest verify-digest image-digest \
        tf-init tf-plan tf-apply tf-destroy tf-output tf-fmt tf-validate tf-docs \
        deploy-dev deploy-staging deploy-prod \
        chartsnap-install chartsnap-snapshot chartsnap-snapshot-all chartsnap-update\
		helm-lint chartsnap-snapshot-all chartsnap-update helm-ci-test

# ---------------------------------------------------------
# Help
# ---------------------------------------------------------
help: ## Show this help message
	@echo ""
	@echo "$(YELLOW)Available commands:$(RESET)"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-25s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ---------------------------------------------------------
# INFRA (Terraform)
# ---------------------------------------------------------

tf-init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform init -reconfigure

tf-plan: ## Terraform plan for environment (ENV=dev/staging/prod)
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform plan -var-file="envs/$(ENV)/terraform.tfvars"

tf-apply: ## Terraform apply
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform apply -var-file="envs/$(ENV)/terraform.tfvars"

tf-destroy: ## Terraform destroy
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform destroy -var-file="envs/$(ENV)/terraform.tfvars"

tf-output: ## Show Terraform outputs
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform output

tf-fmt: ## Format Terraform code
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

tf-validate: ## Validate Terraform code
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform validate

tf-docs: ## Generate Terraform docs
	@command -v terraform-docs >/dev/null 2>&1 || (echo "Installing terraform-docs..." && \
		curl -sSL https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.gz | tar -xz && \
		sudo mv terraform-docs /usr/local/bin/)
	terraform-docs markdown table $(TERRAFORM_DIR) > $(TERRAFORM_DIR)/README.md

# ---------------------------------------------------------
# APP
# ---------------------------------------------------------

test: ## Run unit tests
	cd $(APP_DIR) && mvn -q -DskipTests=false test

run: ## Run locally
	cd $(APP_DIR) && mvn spring-boot:run

# ---------------------------------------------------------
# DOCKER
# ---------------------------------------------------------

build: ## Build Docker image
	docker build -f $(APP_DIR)/Dockerfile -t $(IMAGE) $(APP_DIR)

package: build scan ## Build + scan
	@echo "Build + scan completed"

# ---------------------------------------------------------
# REGISTRY & SECURITY
# ---------------------------------------------------------

login-ecr: ## Login to ECR
	@test -n "$(AWS_ACCOUNT_ID)" || (echo "AWS_ACCOUNT_ID missing"; exit 1)
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(REGISTRY)

scan: ## Trivy scan
	command -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
	trivy image --severity CRITICAL --exit-code 1 --no-progress $(IMAGE)

push: login-ecr ## Push to ECR
	docker push $(IMAGE)

# ---------------------------------------------------------
# COSIGN
# ---------------------------------------------------------
print-cosign-env: ## Debug: print COSIGN_PASSWORD from make
	@echo "COSIGN_PASSWORD='$(COSIGN_PASSWORD)'"


cosign-install: ## Install cosign
	command -v cosign >/dev/null 2>&1 || ( \
		echo "Installing cosign..." && \
		curl -sSfL https://github.com/sigstore/cosign/releases/latest/download/cosign-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64 \
			-o cosign && chmod +x cosign && sudo mv cosign /usr/local/bin/cosign \
	)

cosign-check: ## Ensure keys exist and password set
	@test -f "$(COSIGN_KEY)" || (echo "ERROR: Missing $(COSIGN_KEY)"; exit 1)
	@test -f "$(COSIGN_PUB)" || (echo "ERROR: Missing $(COSIGN_PUB)"; exit 1)
	@test -n "$(COSIGN_PASSWORD)" || (echo "ERROR: COSIGN_PASSWORD is empty but key is encrypted"; exit 1)
	@echo "Local cosign keys found."

image-digest: ## Get digest from ECR
	@echo "Pushing image..."
	docker push $(IMAGE) >/dev/null
	@echo "Retrieving digest..."
	@DIGEST=$$(docker inspect --format='{{index .RepoDigests 0}}' $(IMAGE) | cut -d'@' -f2); \
		echo "IMAGE_DIGEST=$$DIGEST"; \
		echo "Use: make sign-digest IMAGE_DIGEST=$$DIGEST"

sign: cosign-install cosign-check ## Sign by tag
	cosign sign --key $(COSIGN_KEY) $(IMAGE)

verify: cosign-install cosign-check ## Verify tag
	cosign verify --key $(COSIGN_PUB) $(IMAGE)

sign-digest: cosign-install cosign-check ## Sign by digest
	@test -n "$(IMAGE_DIGEST)" || (echo "IMAGE_DIGEST missing"; exit 1)
	cosign sign --key $(COSIGN_KEY) $(IMAGE_REF_BY_DIGEST)

verify-digest: cosign-install cosign-check ## Verify by digest
	@test -n "$(IMAGE_DIGEST)" || (echo "IMAGE_DIGEST missing"; exit 1)
	cosign verify --key $(COSIGN_PUB) $(IMAGE_REF_BY_DIGEST)

# ---------------------------------------------------------
# HELM LINT & SNAPSHOTS
# ---------------------------------------------------------

# ---------------------------------------------------------
# HELM LINT & SNAPSHOTS
# ---------------------------------------------------------

chartsnap-install: ## Install chartsnap
	@helm plugin list 2>/dev/null | grep -q chartsnap \
		|| helm plugin install https://github.com/jlandowner/helm-chartsnap

helm-lint: ## Lint Helm chart with all env values
	@echo "==> helm lint (base chart)"
	helm lint $(CHART_PATH) \
	  --set image.repository=$(IMAGE_REPOSITORY) \
	  --set image.tag=$(IMAGE_TAG)

	@echo "==> helm lint with env values from $(CHART_ENVS_DIR)"
	@for values in $(CHART_ENVS_DIR)/values-*.yaml; do \
		if [ -f $$values ]; then \
			echo "  -> helm lint $(CHART_PATH) -f $$values"; \
			helm lint $(CHART_PATH) -f $$values \
			  --set image.repository=$(IMAGE_REPOSITORY) \
			  --set image.tag=$(IMAGE_TAG); \
		fi; \
	done

chartsnap-snapshot-all: chartsnap-install ## Snapshot all envs (dev/staging/prod)
	@test -d "$(CHART_ENVS_DIR)" || (echo "Env values dir missing: $(CHART_ENVS_DIR)"; exit 1)
	@mkdir -p "$(CHART_SNAPSHOT_OUTPUT_DIR)"
	@echo "==> Generating snapshots from $(CHART_ENVS_DIR)/values-*.yaml into $(CHART_SNAPSHOT_OUTPUT_DIR)/__snapshots__"
	@for values in $(CHART_ENVS_DIR)/values-*.yaml; do \
		if [ -f $$values ]; then \
			echo "  -> $$values"; \
			helm chartsnap -c $(CHART_PATH) -f $$values -o $(CHART_SNAPSHOT_OUTPUT_DIR) -- \
			  --set image.repository=$(IMAGE_REPOSITORY) \
			  --set image.tag=$(IMAGE_TAG); \
		fi; \
	done

chartsnap-update: chartsnap-install ## Update snapshots for all envs (local only)
	@test -d "$(CHART_ENVS_DIR)" || (echo "Env values dir missing: $(CHART_ENVS_DIR)"; exit 1)
	@mkdir -p "$(CHART_SNAPSHOT_OUTPUT_DIR)"
	@echo "==> Updating snapshots in $(CHART_SNAPSHOT_OUTPUT_DIR)/__snapshots__"
	@for values in $(CHART_ENVS_DIR)/values-*.yaml; do \
		if [ -f $$values ]; then \
			echo "  -> $$values (update)"; \
			helm chartsnap -c $(CHART_PATH) -f $$values -o $(CHART_SNAPSHOT_OUTPUT_DIR) -u -- \
			  --set image.repository=$(IMAGE_REPOSITORY) \
			  --set image.tag=$(IMAGE_TAG); \
		fi; \
	done

helm-ci-test: helm-lint chartsnap-snapshot-all ## Helm lint + snapshot tests for dev/staging/prod
	@echo "==> Helm CI tests completed (lint + snapshots for all envs)"



# ---------------------------------------------------------
# DEPLOYMENT
# ---------------------------------------------------------

deploy-dev: ## Deploy to dev
	./$(DEPLOY_SCRIPT) dev "$(IMAGE)" "$(CHART_PATH)"

deploy-staging: ## Deploy to staging
	./$(DEPLOY_SCRIPT) staging "$(IMAGE)" "$(CHART_PATH)"

deploy-prod: ## Deploy to prod
	./$(DEPLOY_SCRIPT) prod "$(IMAGE)" "$(CHART_PATH)"
