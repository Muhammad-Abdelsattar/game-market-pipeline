from typing import Any, Mapping, Optional
from dagster import asset, AssetExecutionContext, DailyPartitionsDefinition
from dagster_dbt import dbt_assets, DbtCliResource, DagsterDbtTranslator
from .resources import dbt_project
from ingestion.pipeline import run_pipeline

daily_partitions = DailyPartitionsDefinition(start_date="2024-01-01")


@asset(
    group_name="ingestion",
    compute_kind="python",
    key_prefix=["rawg_lake"],
    partitions_def=daily_partitions,
)
def raw_genres(context: AssetExecutionContext):
    partition_date = context.partition_key
    context.log.info(f"Ingesting Genres for {partition_date}")

    run_pipeline(
        endpoint="genres",
        max_pages=-1,
        start_date=partition_date,
        end_date=partition_date,
    )


@asset(
    group_name="ingestion",
    compute_kind="python",
    key_prefix=["rawg_lake"],
    partitions_def=daily_partitions,
)
def raw_platforms(context: AssetExecutionContext):
    partition_date = context.partition_key
    run_pipeline(
        endpoint="platforms",
        max_pages=-1,
        start_date=partition_date,
        end_date=partition_date,
    )


@asset(
    group_name="ingestion",
    compute_kind="python",
    key_prefix=["rawg_lake"],
    partitions_def=daily_partitions,
)
def raw_developers(context: AssetExecutionContext):
    partition_date = context.partition_key
    run_pipeline(
        endpoint="developers",
        max_pages=-1,
        start_date=partition_date,
        end_date=partition_date,
    )


@asset(
    group_name="ingestion",
    compute_kind="python",
    key_prefix=["rawg_lake"],
    partitions_def=daily_partitions,
)
def raw_publishers(context: AssetExecutionContext):
    partition_date = context.partition_key
    run_pipeline(
        endpoint="publishers",
        max_pages=-1,
        start_date=partition_date,
        end_date=partition_date,
    )


@asset(
    group_name="ingestion",
    compute_kind="python",
    key_prefix=["rawg_lake"],
    partitions_def=daily_partitions,
)
def raw_games(context: AssetExecutionContext):
    partition_date = context.partition_key
    run_pipeline(
        endpoint="games",
        max_pages=-1,
        start_date=partition_date,
        end_date=partition_date,
    )


class CustomDagsterDbtTranslator(DagsterDbtTranslator):
    def get_group_name(self, dbt_resource_props: Mapping[str, Any]) -> Optional[str]:
        return "analytics"


@dbt_assets(
    manifest=dbt_project.manifest_path,
    dagster_dbt_translator=CustomDagsterDbtTranslator(),
    partitions_def=daily_partitions,
)
def analytics_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
