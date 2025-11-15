# Minimal Makefile for local/CI usage

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

.PHONY: test build scan push sign verify \
        tf-init tf-plan tf-apply tf-destroy tf-output tf-fmt tf-validate

# =========================
# Java / Docker targets
# =========================

test:
	cd $(APP_DIR) && mvn -q -DskipTests=false test

build:
	docker build -f $(APP_DIR)/Dockerfile -t $(IMAGE) $(APP_DIR)

scan:
	command -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
	trivy image --severity CRITICAL --exit-code 1 --no-progress $(IMAGE)

push:
	docker push $(IMAGE)

sign:
	cosign sign --key ./cosign.key $(IMAGE)

verify:
	cosign verify --key ./cosign.pub $(IMAGE)

# =========================
# Terraform helpers
# =========================

tf-init:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform init -reconfigure

tf-plan:
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform plan -var-file="envs/$(ENV)/terraform.tfvars"

tf-apply:
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform apply -var-file="envs/$(ENV)/terraform.tfvars"

tf-destroy:
	@test -f "$(TF_VARS_FILE)" || (echo "Missing tfvars file: $(TF_VARS_FILE)"; exit 1)
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform destroy -var-file="envs/$(ENV)/terraform.tfvars"

tf-output:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform output

tf-fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

tf-validate:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform validate
