# ================================
# AWS CONFIGURATION
# ================================
AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=541872890146

# IAM user credentials for ECR push/pull
AWS_ACCESS_KEY_ID=REPLACE_ME
AWS_SECRET_ACCESS_KEY=REPLACE_ME


# ================================
# DOCKER IMAGE CONFIG
# ================================
APP_NAME=nn-devops-challenge
TAG=local


# ================================
# COSIGN SIGNATURE KEYS (BASE64)
# ================================
# base64 cosign.key | tr -d '\n'
COSIGN_PRIVATE_KEY_B64=REPLACE_ME

# base64 cosign.pub | tr -d '\n'
COSIGN_PUBLIC_KEY_B64=REPLACE_ME

# Optional password for cosign.key
COSIGN_PASSWORD=REPLACE_ME_OR_EMPTY


# ================================
# RENOVATE TOKEN (Azure DevOps PAT)
# ================================
RENOVATE_TOKEN=REPLACE_ME


# ================================
# TERRAFORM / INFRA CONFIG
# ================================
AWS_PROFILE=terraform-nn-devops
TERRAFORM_ENV=dev


# ================================
# OPTIONAL (LOCAL DEV)
# ================================
DOCKER_BUILDKIT=1
