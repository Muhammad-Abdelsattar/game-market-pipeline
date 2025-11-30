# Game Market Pipeline

This project implements a robust, automated data pipeline for ingesting, storing, and analyzing gaming market data. It leverages a modern data stack including **Dagster**, **dbt**, **Snowflake**, and **Docker**, with infrastructure fully defined as code using **Terraform**.

## Project Overview

The pipeline is designed to fetch data from the RAWG API, store it in a Data Lake (S3/MinIO), load it into a Data Warehouse (Snowflake/Postgres), and transform it into analytical models.

### Key Features

- **Infrastructure as Code (IaC)**: Complete cloud environment provisioning (AWS S3, IAM, Snowflake) using Terraform.
- **Orchestration**: Asset-based orchestration with Dagster, featuring partitioned backfills and lineage tracking.
- **Transformation**: Modular SQL transformations with dbt, utilizing staging views and materialized marts.
- **Containerization**: Fully Dockerized environment for consistent local development and cloud deployment.

## Architecture

The pipeline follows a standard ELT (Extract, Load, Transform) pattern:

1.  **Ingestion (Extract)**: Python scripts (`ingestion/`) fetch JSON data from the RAWG API.
2.  **Data Lake (Load)**: Raw JSON files are uploaded to S3 (Cloud) or MinIO (Local).
3.  **Data Warehouse (Load)**: External Tables in Snowflake/DuckDB read directly from the Data Lake.
4.  **Transformation**: dbt models (`analytics/`) clean and structure the data:
    - **Staging Layer**: Views that flatten JSON data and apply basic type casting.
    - **Marts Layer**: Materialized tables representing business entities (Games, Platforms, Developers).

### DWH Design

The Data Warehouse is organized into two primary layers:

- **Staging (`stg_`)**: Lightweight views that sit on top of the raw external tables. These handle JSON parsing and column renaming.
- **Marts (`dim_`, `fct_`)**: The consumption layer. These are materialized as tables for performance and serve as the source of truth for analysis.

### Pipeline Workflow

The orchestration logic is defined in `orchestration/game_dagster/assets.py`. It uses a **Factory Pattern** to dynamically generate assets for different API endpoints (Games, Developers, Publishers), ensuring scalability.

- **Partitioning**: The pipeline uses daily partitions, allowing for incremental data processing and efficient backfills.
- **Backfills**: Historical data retrieval is managed via a dedicated maintenance job (`maintenance.py`), allowing controlled ingestion of past data.

## Quick Start (Local)

To run the entire stack locally using Docker:

1.  **Configure Environment**:

    ```bash
    cp .env.example .env
    # Edit .env with your API keys and credentials
    ```

2.  **Start Services**:

    ```bash
    make start
    ```

    This initializes MinIO (S3), Postgres (Warehouse), and Dagster.

3.  **Access UI**:
    - Dagster: [http://localhost:3000](http://localhost:3000)
    - MinIO: [http://localhost:9001](http://localhost:9001)

For detailed deployment and operational instructions, refer to the [User Manual](./USER_MANUAL.md).

## Roadmap

- [x] Core Pipeline Implementation
- [x] Infrastructure as Code (Terraform)
- [ ] Dashboarding (Superset/Metabase) - _Work in Progress_
- [ ] CI/CD Pipeline (GitHub Actions) - _Work in Progress_
- [ ] Advanced Data Quality Monitoring
- [ ] Adding new gamimg data sources
