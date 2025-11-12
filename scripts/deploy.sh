#!/usr/bin/env bash
set -euo pipefail
ENVIRONMENT="${1:?dev|staging|prod}"
IMAGE="${2:?registry/repo:tag}"
CHART_PATH="${3:-./helm/nn-devops-challenge}"

NS="nn-devops-challeng"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

REPO="$(echo "$IMAGE" | cut -d: -f1)"
TAG="$(echo "$IMAGE" | cut -d: -f2)"

helm upgrade --install "nn-devops-challenge-${ENVIRONMENT}" "$CHART_PATH" \
  --namespace "$NS" \
  --set image.repository="$REPO" \
  --set image.tag="$TAG" \
  --set app.environment="$ENVIRONMENT"
