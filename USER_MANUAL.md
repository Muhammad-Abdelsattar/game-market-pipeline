# User Manual

This manual provides comprehensive instructions for configuring, deploying, and operating the Game Market Pipeline. It covers both local development and cloud deployment workflows.

## Table of Contents

1.  [Prerequisites](#prerequisites)
2.  [Environment Configuration](#environment-configuration)
3.  [Local Development](#local-development)
4.  [Cloud Deployment](#cloud-deployment)
5.  [Operational Guides](#operational-guides)

---

## <a name="prerequisites"></a>1. Prerequisites

Ensure the following tools are installed on your workstation:

*   **Docker & Docker Compose**: For container orchestration.
*   **Make**: For executing project commands.
*   **Terraform**: For infrastructure provisioning.
*   **AWS CLI**: For AWS authentication (configured with `aws configure`).
*   **Python 3.10+**: For local script execution (optional).

---

## <a name="environment-configuration"></a>2. Environment Configuration

The project relies on environment variables for configuration. A template is provided in `.env.example`.

1.  **Create the Environment File**:
    ```bash
    cp .env.example .env
    ```

2.  **Configure Variables**:
    Open `.env` and populate the following:
    *   `RAWG_API_KEY`: Your API key from RAWG.io.
    *   `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`: AWS credentials (required for cloud deployment).
    *   `TF_VAR_snowflake_*`: Snowflake connection details (Account, User, Password) for Terraform.

---

## <a name="local-development"></a>3. Local Development

The local environment replicates the cloud architecture using Docker containers:
*   **MinIO**: Replaces AWS S3.
*   **DuckDB**: Replaces Snowflake.
*   **Dagster**: Orchestrates the pipeline.

### Starting the Environment

Run the following command to initialize and start all services:

```bash
make start
```

This command will:
1.  Create necessary local data directories.
2.  Start the Docker containers in detached mode.
3.  Initialize the MinIO buckets.

### Accessing Services

*   **Dagster UI**: [http://localhost:3000](http://localhost:3000)
*   **MinIO Console**: [http://localhost:9001](http://localhost:9001)

### Stopping Services

To stop the containers:

```bash
make down
```

To stop and **remove all data** (reset):

```bash
make clean
```

---

## <a name="cloud-deployment"></a>4. Cloud Deployment

Deployment is handled via shell scripts that wrap Terraform and Docker commands.

### Infrastructure Provisioning

Use the `deploy_infra.sh` script to provision AWS and Snowflake resources. This script handles the complex dependency between AWS IAM roles and Snowflake Storage Integrations.

```bash
./scripts/deploy_infra.sh
```

**What this script does:**
1.  **Phase 1 (AWS)**: Creates the S3 bucket and IAM Role.
2.  **Phase 2 (Snowflake)**: Creates the Storage Integration using the AWS Role ARN.
3.  **Phase 3 (AWS)**: Updates the IAM Role to trust the Snowflake Storage Integration (Bi-directional trust).
4.  **Phase 4 (Snowflake)**: Creates the External Tables.

### Code Deployment

Use the `build_and_push.sh` script to build Docker images and push them to AWS ECR.

```bash
./scripts/build_and_push.sh
```

**What this script does:**
1.  Authenticates with AWS ECR.
2.  Builds the `ingestion` and `analytics` Docker images.
3.  Tags and pushes the images to your ECR repository.

---

## <a name="operational-guides"></a>5. Operational Guides

### Triggering Pipeline Runs

1.  Navigate to the **Dagster UI**.
2.  Go to **Overview > Jobs**.
3.  Select the desired job (e.g., `game_ingestion_job`).
4.  Click **Launch Run**.

### Running Backfills

We use the `daily_game_market_update` job for both scheduled runs and historical backfills.

1.  Open the **Dagster UI** and navigate to the `daily_game_market_update` job.
2.  Click the **Materialize All** button (or select specific assets).
3.  Click the **Partition** icon to select the date range you want to backfill.
    *   *Tip*: You can filter to "Missing" or "Failed" partitions to only fill gaps.
4.  (Optional) **Configure the Run**:
    You can override the default configuration (e.g., to increase page limits for a deep backfill) by pasting a config YAML like this:

    ```yaml
    ops:
      analytics_dbt_assets:
        config:
          full_refresh: false
          target: dev
      rawg_lake__raw_developers:
        config:
          max_pages: -1
      rawg_lake__raw_games:
        config:
          max_pages: -1
      rawg_lake__raw_genres:
        config:
          max_pages: -1
      rawg_lake__raw_platforms:
        config:
          max_pages: -1
      rawg_lake__raw_publishers:
        config:
          max_pages: -1
    resources:
      dbt:
        config:
          dbt_executable: dbt
          global_config_flags: []
          profiles_dir: /opt/dagster/analytics
          project_dir: /opt/dagster/analytics
      rawg:
        config:
          bucket_name:
            env: DATA_LAKE_BUCKET
          rawg_api_key:
            env: RAWG_API_KEY
    ```
5.  Click **Launch Run**.

### Troubleshooting

*   **Terraform Lock Errors**: If `deploy_infra.sh` fails with a lock error, ensure no other Terraform processes are running. You may need to manually unlock the state using `terraform force-unlock`.
*   **Database Connection Issues**: Ensure the `postgres` container is healthy (`docker ps`). If running locally, check that port 5432 is not occupied by another service.
