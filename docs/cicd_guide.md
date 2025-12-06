# 🚀 CI/CD & Security Guide

This project implements a "Senior-Grade" DevSecOps workflow using **GitHub Actions**. It is designed to be secure (Keyless), robust (Drift Detection), and modular (Decoupled pipelines).

## High-Level Workflow

![CI/CD Diagram](./assets/cicd_architecture.png)

The automation is split into three distinct pipelines to separate concerns:

| Pipeline | Trigger | Purpose | Tools |
| :--- | :--- | :--- | :--- |
| **1. Quality Gate (CI)** | PR to `main` | Static analysis to prevent broken code from merging. | `ruff`, `terraform fmt`, `dbt parse` |
| **2. Infra CD** | Push to `main` (Infra) | Provisions Cloud Resources and updates Config. | `terraform apply`, `bash` (Handshake) |
| **3. App CD** | Push to `main` (Code) | Builds Containers and updates Orchestration. | `docker`, `aws ecr`, `aws ecs` |

---

## 🔐 Security Architecture (OIDC)

We do **NOT** store AWS Access Keys (`AWS_ACCESS_KEY_ID`) in GitHub. Long-lived keys are a security risk.

Instead, we use **OpenID Connect (OIDC)**:
1.  **Trust:** We created an IAM Identity Provider in AWS that trusts GitHub's signing keys.
2.  **Role:** We created a specific role (`github-actions-deployer`) that trusts **ONLY** this specific GitHub Repository.
3.  **Exchange:** When the pipeline runs, GitHub signs a token. AWS verifies the signature and the Repo Name, then grants a temporary, short-lived session token.

### Terraform Implementation
The trust logic is defined in `infrastructure/aws/github_oidc.tf`. It ensures that no other fork of this repo can assume your AWS role.

---

## ⚙️ Configuration Setup

To enable the pipeline in a new environment (e.g., a Fork), you must configure the following in **GitHub Repo Settings > Secrets and variables > Actions**.

### 1. Repository Secrets (Encrypted)
| Secret Name | Value Description | Usage |
| :--- | :--- | :--- |
| `AWS_ACCOUNT_ID` | Your 12-digit AWS Account ID (e.g., `123456789012`). | Used to construct the OIDC Role ARN. |
| `RAWG_API_KEY` | Your API Key from RAWG.io. | Injected into Fargate Containers & Terraform. |
| `SNOWFLAKE_ACCOUNT_NAME` | Your Snowflake Locator (e.g., `xy12345`). | Terraform Provider. |
| `SNOWFLAKE_ORG_NAME` | Your Snowflake Org ID. | Terraform Provider. |
| `SNOWFLAKE_USER` | Service Account Username. | Terraform Provider. |
| `SNOWFLAKE_PASSWORD` | Service Account Password. | Terraform Provider. |

### 2. Repository Variables (Plain Text)
| Variable Name | Value Description | Usage |
| :--- | :--- | :--- |
| `PROJECT_NAME` | e.g., `game-market-analytics`. | Naming AWS resources (Buckets, Clusters). |
| `AWS_REGION` | e.g., `us-east-1`. | Target Region. |

---

## 🛠️ The Pipelines in Detail

### 1. Quality Gate (CI)
Located at `.github/workflows/ci-checks.yml`.
*   **Python:** Runs `ruff` to catch syntax errors and style issues in `ingestion/`.
*   **Terraform:** Runs `terraform fmt` and `terraform validate` to catch configuration errors before they hit AWS.
*   **dbt:** Runs `dbt parse` to ensure SQL models compile correctly and dependencies match.

### 2. Infrastructure Deployment (CD)
Located at `.github/workflows/cd-infra.yml`.
*   **State Management:** Uses S3 Backend (Remote State) to prevent "it works on my machine" conflicts.
*   **The Handshake:** Automatically executes `scripts/deploy_infra.sh` to resolve the circular security dependency between AWS IAM and Snowflake Storage Integrations.

### 3. Application Deployment (CD)
Located at `.github/workflows/cd-app.yml`.
*   **Build:** Builds `ingestion` and `analytics` Docker images.
*   **Push:** Pushes to Amazon ECR.
*   **Deploy:** Executes a **Zero-Downtime Deployment** on AWS Fargate by forcing a new deployment (`aws ecs update-service --force-new-deployment`).

---

## Troubleshooting & Operations

### "State Drift" (Bucket already exists)
If the GitHub pipeline fails saying a resource "Already Exists" but Terraform doesn't know about it, your State File is out of sync.
*   **Fix:** Run `make prod-infra-apply` locally to re-sync the state to S3, or perform a Terraform Import.

### "Not Authorized to Assume Role"
*   **Check 1:** Did you verify the `AWS_ACCOUNT_ID` secret?
*   **Check 2:** Does the Trust Policy in AWS explicitly match your `Owner/Repo-Name`? (Check for typos or case sensitivity).