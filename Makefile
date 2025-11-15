# ---------------------------------------------------------
# Default target: help
# ---------------------------------------------------------
.DEFAULT_GOAL := help

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------
APP_NAME  := nn-devops-challenge
APP_DIR   := app

REGISTRY  ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG       ?= local
IMAGE     := $(REGISTRY)/$(APP_NAME):$(TAG)

# Terraform settings
TERRAFORM_DIR ?= infra
ENV           ?= dev
AWS_PROFILE   ?= terraform-nn-devops
AWS_REGION    ?= eu-west-1

TF_VARS_FILE  := $(TERRAFORM_DIR)/envs/$(ENV)/terraform.tfvars

# Helm / deploy
CHART_PATH    ?= helm/nn-devops-challenge/app
DEPLOY_SCRIPT ?= scripts/deploy.sh

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
        test \
        build \
        scan push sign verify \
        tf-init tf-plan tf-apply tf-destroy tf-output tf-fmt tf-validate tf-docs \
        deploy-dev deploy-staging deploy-prod

# ---------------------------------------------------------
# Help
# ---------------------------------------------------------
help: ## Show this help message
	@echo ""
	@echo "$(YELLOW)Available commands:$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
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

# ---------------------------------------------------------
# IMAGE REGISTRY & SECURITY (scan / push / sign / verify)
# ---------------------------------------------------------

scan: ## Scan Docker image with Trivy (CRITICAL-only)
	command -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
	trivy image --severity CRITICAL --exit-code 1 --no-progress $(IMAGE)

push: ## Push image to registry
	docker push $(IMAGE)

sign: ## Sign image with Cosign
	cosign sign --key ./cosign.key $(IMAGE)

verify: ## Verify Cosign signature
	cosign verify --key ./cosign.pub $(IMAGE)

# ---------------------------------------------------------
# HELM / KUBERNETES DEPLOY
# ---------------------------------------------------------

deploy-dev: ## Deploy to dev namespace using Helm
	./$(DEPLOY_SCRIPT) dev "$(IMAGE)" "$(CHART_PATH)"

deploy-staging: ## Deploy to staging namespace using Helm
	./$(DEPLOY_SCRIPT) staging "$(IMAGE)" "$(CHART_PATH)"

deploy-prod: ## Deploy to prod namespace using Helm
	./$(DEPLOY_SCRIPT) prod "$(IMAGE)" "$(CHART_PATH)"
