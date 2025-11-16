# ---------------------------------------------------------
# Load .env if present
# ---------------------------------------------------------
ifneq (,$(wildcard .env))
include .env
# Export all keys from .env as environment vars for shell commands
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

# Terraform settings
TERRAFORM_DIR ?= infra
ENV           ?= dev
AWS_PROFILE   ?= terraform-nn-devops

TF_VARS_FILE  := $(TERRAFORM_DIR)/envs/$(ENV)/terraform.tfvars

# Helm / deploy
CHART_PATH    ?= helm/
DEPLOY_SCRIPT ?= scripts/deploy.sh

# Helm chartsnap (snapshot testing)
CHART_SNAPSHOT_VALUES_DIR  ?= $(CHART_PATH)/ci
CHART_SNAPSHOT_OUTPUT_DIR  ?= $(CHART_SNAPSHOT_VALUES_DIR)/snapshots

# Cosign key file paths
COSIGN_KEY ?= cosign.cert/cosign.key
COSIGN_PUB ?= cosign.cert/cosign.pub

# Base64 decode (use -d, works fine in macOS and Linux)
BASE64_DECODE := base64 -d

# Signing by digest
IMAGE_DIGEST ?=
IMAGE_REF_BY_DIGEST := $(REGISTRY)/$(APP_NAME)@$(IMAGE_DIGEST)

# ---------------------------------------------------------
# Colors for help output
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
        cosign-install cosign-decode-keys sign verify sign-digest verify-digest image-digest \
        tf-init tf-plan tf-apply tf-destroy tf-output tf-fmt tf-validate tf-docs \
        deploy-dev deploy-staging deploy-prod \
        chartsnap-install chartsnap-snapshot chartsnap-snapshot-all chartsnap-update

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

tf-plan: ## Terraform plan for selected environment (ENV=dev/staging/prod)
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)" && exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform plan -var-file="envs/$(ENV)/terraform.tfvars"

tf-apply: ## Terraform apply for selected environment
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)" && exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform apply -var-file="envs/$(ENV)/terraform.tfvars"

tf-destroy: ## Terraform destroy for selected environment
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)" && exit 1)
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform destroy -var-file="envs/$(ENV)/terraform.tfvars"

tf-output: ## Show Terraform outputs
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform output

tf-fmt: ## Format Terraform code
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

tf-validate: ## Validate Terraform code
	cd $(TERRAFORM_DIR) && AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform validate

tf-docs: ## Generate Terraform documentation (terraform-docs)
	@command -v terraform-docs >/dev/null 2>&1 || (echo "Installing terraform-docs..." && \
		curl -sSL https://github.com/terraform-docs/terraform-docs/releases/latest/download/terraform-docs-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64.tar.gz | tar -xz && \
		sudo mv terraform-docs /usr/local/bin/)
	@echo "Generating documentation..."
	terraform-docs markdown table $(TERRAFORM_DIR) > $(TERRAFORM_DIR)/README.md
	for module in $(TERRAFORM_DIR)/modules/*; do \
		if [ -d $$module ]; then \
			echo "Generating docs for $$module"; \
			terraform-docs markdown table $$module > $$module/README.md; \
		fi \
	done

# ---------------------------------------------------------
# APP (Java / Spring Boot)
# ---------------------------------------------------------

test: ## Run unit tests
	cd $(APP_DIR) && mvn -q -DskipTests=false test

run: ## Run Spring Boot locally
	cd $(APP_DIR) && mvn spring-boot:run

# ---------------------------------------------------------
# DOCKER (Build)
# ---------------------------------------------------------

build: ## Build Docker image
	docker build -f $(APP_DIR)/Dockerfile -t $(IMAGE) $(APP_DIR)

package: build scan ## Build and scan Docker image
	@echo "Build + scan completed"

# ---------------------------------------------------------
# IMAGE REGISTRY & SECURITY
# ---------------------------------------------------------

login-ecr: ## Login to AWS ECR
	@test -n "$(AWS_ACCOUNT_ID)" || (echo "AWS_ACCOUNT_ID is not set" && exit 1)
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(REGISTRY)

scan: ## Scan Docker image with Trivy
	command -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
	trivy image --severity CRITICAL --exit-code 1 --no-progress $(IMAGE)

push: login-ecr ## Push image to ECR
	docker push $(IMAGE)

# ---------------------------------------------------------
# COSIGN (local keys in cosign.cert/)
# ---------------------------------------------------------

# Paths to your local keys
COSIGN_KEY := cosign.cert/cosign.key
COSIGN_PUB := cosign.cert/cosign.pub

cosign-install: ## Install cosign if missing
	command -v cosign >/dev/null 2>&1 || ( \
		echo "Installing cosign..." && \
		curl -sSfL https://github.com/sigstore/cosign/releases/latest/download/cosign-$(shell uname -s | tr '[:upper:]' '[:lower:]')-amd64 \
			-o cosign && chmod +x cosign && sudo mv cosign /usr/local/bin/cosign \
	)

image-digest: ## Get remote image digest after push
	@test -n "$(IMAGE)" || (echo "IMAGE variable is empty" && exit 1)
	@echo "Pushing image (required for digest)..."
	docker push $(IMAGE) >/dev/null
	@echo ""
	@echo "Retrieving remote digest..."
	@DIGEST=$$(docker inspect --format='{{index .RepoDigests 0}}' $(IMAGE) | cut -d'@' -f2); \
		echo "IMAGE_DIGEST=$$DIGEST"; \
		echo ""; \
		echo "👉 Use it like:"; \
		echo "make sign-digest IMAGE_DIGEST=$$DIGEST"

# No decoding needed anymore, just ensure files exist
cosign-check: ## Ensure local cosign keys exist
	@test -f "$(COSIGN_KEY)" || (echo "ERROR: Missing $(COSIGN_KEY)"; exit 1)
	@test -f "$(COSIGN_PUB)" || (echo "ERROR: Missing $(COSIGN_PUB)"; exit 1)
	@echo "Local cosign keys found."

sign: cosign-install cosign-check ## Sign image by tag
	cosign sign --key $(COSIGN_KEY) $(IMAGE)

verify: cosign-install cosign-check ## Verify signature by tag
	cosign verify --key $(COSIGN_PUB) $(IMAGE)

sign-digest: cosign-install cosign-check ## Sign image by digest
	@test -n "$(IMAGE_DIGEST)" || (echo "IMAGE_DIGEST missing"; exit 1)
	cosign sign --key $(COSIGN_KEY) $(IMAGE_REF_BY_DIGEST)

verify-digest: cosign-install cosign-check ## Verify signature by digest
	@test -n "$(IMAGE_DIGEST)" || (echo "IMAGE_DIGEST missing"; exit 1)
	cosign verify --key $(COSIGN_PUB) $(IMAGE_REF_BY_DIGEST)


# ---------------------------------------------------------
# HELM CHART SNAPSHOTS
# ---------------------------------------------------------

chartsnap-install: ## Install helm-chartsnap plugin
	@helm plugin list 2>/dev/null | grep -q chartsnap \
		&& echo "chartsnap already installed" \
		|| helm plugin install https://github.com/jlandowner/helm-chartsnap

chartsnap-snapshot: chartsnap-install ## Snapshot default values
	@mkdir -p "$(CHART_SNAPSHOT_OUTPUT_DIR)"
	helm chartsnap -c $(CHART_PATH) -o $(CHART_SNAPSHOT_OUTPUT_DIR)

chartsnap-snapshot-all: chartsnap-install ## Snapshot all test values
	@test -d "$(CHART_SNAPSHOT_VALUES_DIR)" || (echo "Missing values dir"; exit 1)
	@mkdir -p "$(CHART_SNAPSHOT_OUTPUT_DIR)"
	helm chartsnap -c $(CHART_PATH) -f $(CHART_SNAPSHOT_VALUES_DIR) -o $(CHART_SNAPSHOT_OUTPUT_DIR)

chartsnap-update: chartsnap-install ## Update snapshots
	@mkdir -p "$(CHART_SNAPSHOT_OUTPUT_DIR)"
	helm chartsnap -c $(CHART_PATH) -f $(CHART_SNAPSHOT_VALUES_DIR) -o $(CHART_SNAPSHOT_OUTPUT_DIR) -u

# ---------------------------------------------------------
# HELM DEPLOYMENT
# ---------------------------------------------------------

deploy-dev: ## Deploy to dev namespace
	./$(DEPLOY_SCRIPT) dev "$(IMAGE)" "$(CHART_PATH)"

deploy-staging: ## Deploy to staging namespace
	./$(DEPLOY_SCRIPT) staging "$(IMAGE)" "$(CHART_PATH)"

deploy-prod: ## Deploy to prod namespace
	./$(DEPLOY_SCRIPT) prod "$(IMAGE)" "$(CHART_PATH)"
