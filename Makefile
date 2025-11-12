# Minimal Makefile for local/CI usage

APP_NAME := nn-devops-challenge
IMAGE    := $(REGISTRY)/$(APP_NAME):$(TAG)
REGISTRY ?= localhost:5000
TAG      ?= local

.PHONY: test build scan push sign verify

test:
\tmvn -q -DskipTests=false test

build:
\tdocker build -t $(IMAGE) .

scan:
\tcommand -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
\ttrivy image --severity CRITICAL --exit-code 1 --no-progress $(IMAGE)

push:
\tdocker push $(IMAGE)

sign:
\tcosign sign --key ./cosign.key $(IMAGE)

verify:
\tcosign verify --key ./cosign.pub $(IMAGE)
