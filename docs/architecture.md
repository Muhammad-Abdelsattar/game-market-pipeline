# 🏗️ System Architecture

This document outlines the architectural patterns used in the Game Market Pipeline. The system follows a **Lambda Architecture** approach, capable of handling historical backfills and daily incremental updates using the same code paths.

## High-Level Design

![Architecture Diagram](./assets/architecture.png)

The pipeline is split into three logical planes:

1.  **Control Plane (Orchestration):** Triggers tasks based on time (Schedule) or partitions (Backfill).
2.  **Compute Plane (Execution):** Stateless containers that perform the actual work.
3.  **Data Plane (Storage):** The flow of data from API to Data Warehouse.

## Core Concepts

### 1. Hybrid Environment Abstraction
To ensure development velocity without incurring cloud costs, the system uses abstraction layers to treat Local and Cloud environments identically.

*   **Ingestion Layer:** The `S3Writer` class checks for an `S3_ENDPOINT` environment variable. If present (Local), it talks to MinIO. If absent (Cloud), it defaults to AWS S3.
*   **Warehouse Layer:** dbt uses `profiles.yml` to switch adapters.
    *   **Dev:** Uses `dbt-duckdb` with the `httpfs` extension to query MinIO directly.
    *   **Prod:** Uses `dbt-snowflake` to query External Tables.
*   **SQL Dialect:** Jinja Macros (`macros/`) abstract SQL differences (e.g., `UNNEST` vs `LATERAL FLATTEN`) so the business logic models remain identical.

### 2. The ELT Pattern (Extract, Load, Transform)
We strictly follow ELT over ETL.
1.  **Extract:** Python scripts fetch JSON from RAWG.
2.  **Load:** JSON is dumped *as-is* into the Data Lake (S3/MinIO). No transformation happens here.
3.  **Transform:** The Data Warehouse loads the raw files and dbt handles parsing, cleaning, and modeling inside the warehouse.

### 3. Orchestration Logic
*   **Asset Factory:** Instead of hardcoding tasks for every API endpoint, `orchestration/game_dagster/assets.py` uses a Factory Pattern. It iterates over a list (`['games', 'genres', ...]`) and dynamically generates Dagster assets.
*   **Partitions:** The pipeline uses Daily Partitions. A run for `2024-01-01` will:
    1.  Pass `2024-01-01` to the API script (filtering the `updated` query param).
    2.  Save data to `s3://.../run_date=2024-01-01/`.
    3.  Trigger dbt to process only that partition (in Incremental models).
