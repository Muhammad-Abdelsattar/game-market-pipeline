from dagster import file_relative_path
from dagster_dbt import DbtProject

DBT_PROJECT_DIR = "/opt/dagster/analytics"

dbt_project = DbtProject(
    project_dir=DBT_PROJECT_DIR,
    packaged_project_dir=DBT_PROJECT_DIR,
)
