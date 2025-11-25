from dagster import (
    Definitions,
    load_assets_from_modules,
    define_asset_job,
    ScheduleDefinition,
)
from dagster_dbt import DbtCliResource
from . import assets
from .resources import dbt_project
from .maintenance import historical_backfill_job 

all_assets = load_assets_from_modules([assets])

daily_update_job = define_asset_job(
    name="daily_game_market_update",
    selection="*",
    partitions_def=assets.daily_partitions,
)

daily_schedule = ScheduleDefinition(
    job=daily_update_job,
    cron_schedule="0 0 * * *",
)

defs = Definitions(
    assets=all_assets,
    jobs=[daily_update_job, historical_backfill_job],
    schedules=[daily_schedule],
    resources={
        "dbt": DbtCliResource(project_dir=dbt_project),
    },
)
