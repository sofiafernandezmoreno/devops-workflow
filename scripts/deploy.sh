#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?dev|staging|prod}"
IMAGE="${2:?registry/repo:tag}"
CHART_PATH="${3:-./helm/nn-devops-challenge/app}"

case "${ENVIRONMENT}" in
  dev)
    NAMESPACE="nn-devops-dev"
    ;;
  staging)
    NAMESPACE="nn-devops-staging"
    ;;
  prod)
    NAMESPACE="nn-devops-prod"
    ;;
  *)
    echo "Unknown environment: ${ENVIRONMENT} (expected dev|staging|prod)" >&2
    exit 1
    ;;
esac

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || \
  kubectl create namespace "${NAMESPACE}"

REPO="${IMAGE%%:*}"
TAG="${IMAGE##*:}"

helm upgrade --install "nn-devops-challenge-${ENVIRONMENT}" "${CHART_PATH}" \
  --namespace "${NAMESPACE}" \
  --set image.repository="${REPO}" \
  --set image.tag="${TAG}" \
  --set app.environment="${ENVIRONMENT}"
