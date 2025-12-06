# Game Market Data Pipeline

![Status](https://img.shields.io/badge/Status-Active-success)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-blue)
![Security](https://img.shields.io/badge/Auth-AWS%20OIDC-red)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)

A robust, environment-agnostic ELT pipeline designed to ingest gaming market data from the RAWG API, process it using a modern data stack, and serve analytical models.

The project runs in two modes with complete feature parity:
1.  **Local Mode:** Docker, MinIO (S3), DuckDB, Dagster.
2.  **Cloud Mode:** AWS ECS, S3, Snowflake, Step Functions.

## 🏗️ Architecture

The system uses a **Hybrid Architecture** to optimize for both Developer Experience (Local) and Cost/Scale (Cloud).

![Architecture Diagram](docs/assets/architecture.png)

## 🔄 CI/CD & DevOps

We utilize **GitHub Actions** for a fully automated DevSecOps workflow. 
*   **Security:** Keyless authentication via **AWS OIDC** (No long-lived access keys).
*   **Pipelines:** Decoupled pipelines for Quality Assurance, Infrastructure, and Application Code.

![CI/CD Architecture](docs/assets/cicd_architecture.png)

## 📚 Documentation

| Guide | Description |
| :--- | :--- |
| **[Architecture](./docs/architecture.md)** | Deep dive into Idempotent Ingestion, Hybrid Design, and Orchestration. |
| **[CI/CD & Security](./docs/cicd_guide.md)** | **(New)** How the GitHub Actions pipelines, OIDC, and Release strategies work. |
| **[Infrastructure](./docs/infrastructure.md)** | AWS Resource map, S3 Backend State, and Partitioning logic. |
| **[DWH Design](./docs/dwh_design.md)** | Incremental Merge strategy (Natural Keys), Partitioning, and Data Quality. |
| **[Local Setup](./docs/local_setup.md)** | How to run the pipeline locally with Docker. |

## 🚀 Key Features

*   **Idempotent Ingestion:** "Smart Resume" logic checks S3 before fetching, preventing API rate-limit exhaustion and allowing cost-free retries.
*   **Infrastructure as Code:** Complete AWS & Snowflake environment provisioning via Terraform with **Remote S3 State Locking**.
*   **Zero-Drift Config:** A single `config/endpoints.json` acts as the Source of Truth for both Python ingestion and Terraform resources.
*   **Secure Automation:** Deployment uses OIDC Identity Providers, ensuring least-privilege access without sharing static credentials.
*   **Optimized Warehousing:** Snowflake External Tables use **Partition Pruning** to minimize S3 scanning costs.

## 🛠️ Tech Stack

*   **Ingestion:** Python 3.12, Tenacity (Retries), Boto3.
*   **Storage:** AWS S3 (Prod) / MinIO (Dev).
*   **Compute:** AWS Fargate (Prod) / Docker Containers (Dev).
*   **Orchestration:** Dagster (Local) / AWS Step Functions + EventBridge (Prod).
*   **Transformation:** dbt (Data Build Tool) with Natural Key Merging.
*   **Warehouse:** Snowflake (Prod) / DuckDB (Dev).
*   **CI/CD:** GitHub Actions, Make.

## ⚡ Quick Start

### A. Local Development (Docker)
1.  **Configure Environment**:
    ```bash
    cp .env.example .env
    # Add your RAWG_API_KEY
    ```
2.  **Start Services**:
    ```bash
    make local-start
    ```
3.  **Access UI**:
    *   Dagster: [http://localhost:3000](http://localhost:3000)
    *   MinIO: [http://localhost:9001](http://localhost:9001)

### B. Production Deployment (CI/CD)
Manual deployment is only required for the initial bootstrap. Once the OIDC Trust is established, **GitHub Actions** handles all updates.

1.  **Fork Repository**.
2.  **Configure Secrets**: Add AWS Account ID, API Keys, and Snowflake Credentials to GitHub Secrets (See [CI/CD Guide](./docs/cicd_guide.md)).
3.  **Bootstrap OIDC**:
    ```bash
    export TF_VAR_github_repo="your-username/your-repo"
    make prod-infra-apply
    ```
4.  **Push**: Any commit to `main` will now automatically deploy Infrastructure and Code.