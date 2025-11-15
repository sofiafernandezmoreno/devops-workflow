# Minimal Makefile for local/CI usage

APP_NAME := nn-devops-challenge
REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG      ?= local
IMAGE    := $(REGISTRY)/$(APP_NAME):$(TAG)

# Terraform settings
TERRAFORM_DIR        ?= infra
AWS_PROFILE          ?= terraform-nn-devops
AWS_REGION           ?= eu-west-1
TF_VAR_use_default_vpc ?= true

.PHONY: test build scan push sign verify \
        tf-init tf-plan tf-apply tf-destroy tf-output tf-fmt tf-validate

# =========================
# Java / Docker targets
# =========================

test:
	mvn -q -DskipTests=false test

build:
	docker build -t $(IMAGE) .

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
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform plan -var="use_default_vpc=$(TF_VAR_use_default_vpc)"

# Interactive apply (Terraform will still ask "Only 'yes' will be accepted")
tf-apply:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform apply -var="use_default_vpc=$(TF_VAR_use_default_vpc)"

# Destroy all infra created by this Terraform project
tf-destroy:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform destroy -var="use_default_vpc=$(TF_VAR_use_default_vpc)"

# Show useful outputs (ECR URL, cluster name, etc.)
tf-output:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform output

# Format and validate Terraform code
tf-fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

tf-validate:
	cd $(TERRAFORM_DIR) && \
	AWS_PROFILE=$(AWS_PROFILE) AWS_REGION=$(AWS_REGION) terraform validate
