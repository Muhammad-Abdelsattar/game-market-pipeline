from dagster import (
    Definitions,
    load_assets_from_modules,
    define_asset_job,
    ScheduleDefinition,
)
from dagster_dbt import DbtCliResource
from . import assets
from .resources import dbt_project, RawgIngestionResource

# We explicitly load the dbt assets, and append the generated python assets
all_assets = [assets.analytics_dbt_assets] + assets.ingestion_assets

# A job that runs everything (Ingestion -> DBT) automatically linked by Dagster
daily_update_job = define_asset_job(
    name="daily_game_market_update",
    selection="*",  # Selects all assets in the graph
    partitions_def=assets.daily_partitions,
)

# Define Schedule
daily_schedule = ScheduleDefinition(
    job=daily_update_job,
    cron_schedule="0 0 * * *",
)

# Final Definitions
defs = Definitions(
    assets=all_assets,
    jobs=[daily_update_job],
    schedules=[daily_schedule],
    resources={
        # The dbt CLI wrapper
        "dbt": DbtCliResource(project_dir=dbt_project),
        # Our new Ingestion wrapper
        "rawg": RawgIngestionResource(),
    },
)
