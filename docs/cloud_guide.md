# ☁️ Cloud Deployment Guide

This guide covers deploying the pipeline to a production environment using **AWS** (Ingestion/Storage) and **Snowflake** (Warehousing).

## 1. Architecture Overview

In Production, the "Local" services are replaced by managed cloud services:
*   **Orchestrator**: AWS Step Functions triggers ECS Tasks.
*   **Compute**: AWS Fargate (Serverless Containers).
*   **Storage**: AWS S3.
*   **Warehouse**: Snowflake (Loading data via Storage Integrations).

## 2. Prerequisites

1.  **AWS Account**: With Admin access (for IAM/S3/ECS creation).
2.  **AWS CLI**: Configured locally (`aws configure`).
3.  **Snowflake Account**: You need `ACCOUNTADMIN` rights to create Storage Integrations.
4.  **Terraform**: v1.0+.

## 3. Configuration

Open your `.env` file and ensure the Production variables are set:

```ini
# AWS Credentials (Terraform uses these)
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1

# Snowflake Credentials (Used by dbt and Terraform)
TF_VAR_snowflake_account_name=xy12345
TF_VAR_snowflake_username=data_eng_user
TF_VAR_snowflake_password=secure_password
```

## 4. The Deployment "Handshake"

Deploying this stack is not a single click because of a circular security dependency:
1.  **AWS** needs to know the **Snowflake User ARN** to allow access.
2.  **Snowflake** needs to know the **AWS Role ARN** to create the Integration.

We have automated this into a single script: `scripts/deploy_infra.sh`.

### Deploying Infrastructure

Run the following command:

```bash
make prod-infra-apply
```

**What this script does automatically:**
1.  **Phase 1 (AWS)**: Creates S3 Bucket & IAM Role (with no permissions yet).
2.  **Phase 2 (Snowflake)**: Creates the Storage Integration pointing to that IAM Role.
3.  **Phase 3 (Handshake)**: Captures the `EXTERNAL_ID` from Snowflake and updates the AWS IAM Role Trust Policy.
4.  **Phase 4 (Final)**: Creates External Tables in Snowflake now that access is secure.

## 5. Deploying Code

Once infrastructure is up, you need to build the Docker images and push them to AWS ECR (Elastic Container Registry).

```bash
make prod-build-push
```
*   Builds `game-market-ingestion` and `game-market-analytics`.
*   Pushes them to the ECR repositories created by Terraform.

### Full Deployment (One Command)
To do both Infrastructure and Code deployment:
```bash
make prod-deploy-all
```

## 6. Running in Production

### Triggering the Pipeline
The production pipeline is managed by **AWS Step Functions**.

1.  Log into AWS Console -> **Step Functions**.
2.  Find `game-market-pipeline`.
3.  Click **Start Execution**.
4.  (Optional) Pass Input JSON:
    ```json
    {
      "comment": "Manual run for specific dates",
      "overrides": {
         "containerOverrides": [
            { "name": "ingestion-container", "command": ["--start_date", "2024-01-01", "--end_date", "2024-01-01"] }
         ]
      }
    }
    ```

### Monitoring
*   **ECS**: View logs in CloudWatch Log Groups (`/ecs/ingestion`, `/ecs/analytics`).
*   **Snowflake**: Check `GAME_MARKET_DB.RAW` tables to see if data is arriving.

## 7. Teardown

To destroy all cloud resources and stop billing:

```bash
make prod-infra-destroy
```

**Note**: You may need to manually empty the S3 bucket before Terraform can delete it, depending on the `force_destroy` setting in `s3.tf`.
