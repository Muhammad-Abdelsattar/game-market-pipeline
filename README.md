# Game Market Data Pipeline

![Status](https://img.shields.io/badge/Status-Active-success)
![Stack](https://img.shields.io/badge/Stack-Hybrid%20(Local%2FCloud)-blue)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)

A robust, environment-agnostic ELT pipeline designed to ingest gaming market data from the RAWG API, process it using a modern data stack, and serve analytical models.

The project runs in two modes with complete feature parity:
1.  **Local Mode:** Docker, MinIO (S3), DuckDB, Dagster.
2.  **Cloud Mode:** AWS ECS, S3, Snowflake, Step Functions.

![Architecture Diagram](docs/assets/architecture.png)

## 📚 Documentation

| Guide | Description |
| :--- | :--- |
| **[Architecture](./docs/architecture.md)** | Deep dive into the Pipeline Logic, Hybrid design, and Orchestration. |
| **[Infrastructure](./docs/infrastructure.md)** | AWS Resource map, Security/IAM logic, and Terraform implementation. |
| **[DWH Design](./docs/dwh_design.md)** | Data Modeling strategy, JSON handling, and Lineage. |
| **[Local Setup](./docs/local_setup.md)** | How to run the pipeline locally with Docker. |
| **[Cloud Deployment](./docs/cloud_deployment.md)** | How to deploy to production using Terraform. |

## 🚀 Key Features

*   **Hybrid Abstraction:** The code (`ingestion/` and `analytics/`) is unaware of the environment. It seamlessly switches between S3/MinIO and Snowflake/DuckDB.
*   **Infrastructure as Code:** Complete AWS & Snowflake environment provisioning via Terraform.
*   **Asset-Based Orchestration:** Dynamically generated assets for API endpoints using a Factory Pattern in Dagster.
*   **Incremental Loading:** Efficiently processes only new data using Partition logic (Hive-style S3 partitions).
*   **Self-Healing:** API calls use exponential backoff (`tenacity`) to handle rate limits.

## 🛠️ Tech Stack

*   **Ingestion:** Python 3.12, Boto3, Requests.
*   **Storage:** AWS S3 (Prod) / MinIO (Dev).
*   **Compute:** AWS Fargate (Prod) / Docker Containers (Dev).
*   **Orchestration:** Dagster (Local) / AWS Step Functions (Prod).
*   **Transformation:** dbt (Data Build Tool).
*   **Warehouse:** Snowflake (Prod) / DuckDB (Dev).
*   **IaC:** Terraform.

## ⚡ Quick Start (Local)

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


For detailed instructions, see the [Local Setup Guide](./docs/local_setup.md).