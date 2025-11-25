from dagster import op, job, Config, OpExecutionContext, In, Nothing
from dagster_dbt import DbtCliResource
from ingestion.pipeline import run_pipeline


class BackfillConfig(Config):
    games_pages: int = 50
    devs_pages: int = 20
    full_refresh: bool = True


@op
def fetch_history_games(context: OpExecutionContext, config: BackfillConfig):
    context.log.info(f"Fetching Games History: {config.games_pages} pages")
    run_pipeline(
        endpoint="games", max_pages=config.games_pages, start_date=None, end_date=None
    )


@op
def fetch_history_devs(context: OpExecutionContext, config: BackfillConfig):
    context.log.info(f"Fetching Developers History: {config.devs_pages} pages")
    run_pipeline(
        endpoint="developers",
        max_pages=config.devs_pages,
        start_date=None,
        end_date=None,
    )


@op(ins={"start_after": In(Nothing)})
def dbt_custom_run(
    context: OpExecutionContext, dbt: DbtCliResource, config: BackfillConfig
):
    args = ["build"]
    if config.full_refresh:
        context.log.info("Adding --full-refresh flag")
        args.append("--full-refresh")

    yield from dbt.cli(args, context=context).stream()


@job(name="manual_historical_backfill")
def historical_backfill_job():
    g = fetch_history_games()
    d = fetch_history_devs()

    # "Don't run dbt until 'g' and 'd' are finished"
    dbt_custom_run(start_after=[g, d])
