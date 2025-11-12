# 🏗️ Terraform Infrastructure — nn-devops-challenge

This folder provisions all AWS resources needed for the Azure DevOps CI/CD pipeline:
- Amazon EKS Cluster (v1.30)
- Amazon ECR Repository
- IAM User for Azure DevOps (with ECR + EKS access)
- Optional VPC creation (toggle between default or custom)

---

## ⚙️ Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform ≥ 1.6
- Admin permissions in your AWS account (for creating IAM, EKS, and VPC)

---

## 🚀 Usage

### 1️⃣ Initialize Terraform

```bash
cd infra
terraform init
