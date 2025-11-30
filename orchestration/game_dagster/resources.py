import os
from pathlib import Path
from dagster import ConfigurableResource, EnvVar
from dagster_dbt import DbtProject


def get_dbt_project_path() -> Path:
    """
    Robustly finds the dbt project path.
    1. PRIORITIZE ENV VAR: In Docker, DBT_PROJECT_DIR is explicitly set in docker-compose.
       This is the safest way because Docker file structures often differ from local.
    2. FALLBACK LOCAL: If not set, assume we are running locally and look for 'analytics'
       relative to this file.
    """
    # Check the standard dbt environment variable first
    env_path = os.getenv("DBT_PROJECT_DIR")
    if env_path:
        return Path(env_path)

    # Fallback: We are likely local (running 'dagster dev') without the full env context.
    # We calculate the path relative to: orchestration/game_dagster/resources.py
    # Logic: resources.py -> game_dagster -> orchestration -> ROOT -> analytics
    current_file = Path(__file__)
    project_root = current_file.parent.parent.parent
    return project_root.joinpath("analytics")


# Initialize the project using the robust path
dbt_project = DbtProject(
    project_dir=get_dbt_project_path(),
)


class RawgIngestionResource(ConfigurableResource):
    rawg_api_key: str = EnvVar("RAWG_API_KEY")
    bucket_name: str = EnvVar("DATA_LAKE_BUCKET")

    def ingest_endpoint(self, endpoint: str, date: str, max_pages: int) -> dict:
        from ingestion.pipeline import run_pipeline

        run_pipeline(
            endpoint=endpoint,
            max_pages=max_pages,  # Use the argument passed from the asset
            start_date=date,
            end_date=date,
        )

        s3_path = f"s3://{self.bucket_name}/raw/{endpoint}/run_date={date}/"
        return {"endpoint": endpoint, "date": date, "s3_path": s3_path}

