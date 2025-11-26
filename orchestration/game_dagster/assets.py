from typing import Any, Mapping, Optional, List

from dagster import (
    asset,
    AssetExecutionContext,
    DailyPartitionsDefinition,
    AssetKey,
    MaterializeResult,
    MetadataValue,
    Config,
)
from dagster_dbt import dbt_assets, DbtCliResource, DagsterDbtTranslator

from .resources import dbt_project, RawgIngestionResource

#  PARTITIONING
# We define the start date once. This is applied to both Ingestion and dbt.
daily_partitions = DailyPartitionsDefinition(start_date="2024-01-01")


#  PYTHON ASSETS (INGESTION) - The Factory Pattern
# List of endpoints we want to ingest from RAWG API
ENDPOINTS = ["genres", "platforms", "developers", "publishers", "games"]


class RawgConfig(Config):
    max_pages: int = -1


# 2. Update the Factory
def build_rawg_asset(endpoint_name: str, default_pages: int = -1):

    @asset(
        name=f"raw_{endpoint_name}",
        key_prefix=["rawg_lake"],
        group_name="ingestion",
        compute_kind="python",
        partitions_def=daily_partitions,
    )
    def _ingest_asset(
        context: AssetExecutionContext,
        rawg: RawgIngestionResource,
        config: RawgConfig,  # <--- Inject Config here
    ):
        partition_date = context.partition_key

        # LOGIC: Check if user provided a config override in UI.
        # If config.max_pages is still the default (-1), we can choose to use the
        # 'default_pages' passed to the factory, or just trust the config.
        # Here we simple trust the config object.

        current_limit = config.max_pages

        context.log.info(f"🚀 Ingesting {endpoint_name}. Limit: {current_limit} pages.")

        result_meta = rawg.ingest_endpoint(
            endpoint=endpoint_name,
            date=partition_date,
            max_pages=current_limit,
        )

        return MaterializeResult(
            metadata={
                "s3_path": MetadataValue.path(result_meta["s3_path"]),
                "partition_date": result_meta["date"],
                "pages_limit": current_limit,
            }
        )

    return _ingest_asset


# You can now specify different needs for different endpoints
ingestion_assets = [
    build_rawg_asset("genres"),  # Defaults to -1
    build_rawg_asset("platforms"),
    build_rawg_asset("developers"),
    build_rawg_asset("publishers"),
    build_rawg_asset("games"),
]


#  DBT TRANSLATOR (Fixing Lineage)
class CustomDagsterDbtTranslator(DagsterDbtTranslator):
    def get_asset_key(self, dbt_resource_props: Mapping[str, Any]) -> AssetKey:
        """
        This is the glue that connects Python Assets to dbt Sources.
        It looks at sources.yml and maps them to the keys we defined above.
        """
        node_type = dbt_resource_props.get("resource_type")

        # If the dbt node is a 'source' (from sources.yml)
        if node_type == "source":
            source_name = dbt_resource_props["source_name"]  # e.g., 'rawg_lake'
            table_name = dbt_resource_props["name"]  # e.g., 'raw_games'

            # Return the EXACT key matching the Python asset: ["rawg_lake", "raw_games"]
            return AssetKey([source_name, table_name])

        return super().get_asset_key(dbt_resource_props)

    def get_group_name(self, dbt_resource_props: Mapping[str, Any]) -> Optional[str]:
        # Force all dbt models into the 'analytics' group in the UI
        return "analytics"


# DBT ASSETS (TRANSFORMATION)
# Define a Config Schema to allow passing flags from the UI
class DbtConfig(Config):
    full_refresh: bool = False


@dbt_assets(
    manifest=dbt_project.manifest_path,
    dagster_dbt_translator=CustomDagsterDbtTranslator(),
    partitions_def=daily_partitions,
)
def analytics_dbt_assets(
    context: AssetExecutionContext, dbt: DbtCliResource, config: DbtConfig
):
    """
    Runs `dbt build` for the specific partition date.
    """
    dbt_args = ["build"]

    # Handle the UI Configuration for Full Refresh
    if config.full_refresh:
        context.log.info("🔄 Full Refresh Flag detected! Appending --full-refresh")
        dbt_args.append("--full-refresh")

    # Dagster automatically passes the partition variables to dbt
    # (dbt_vars={ "partition_key": "2024-01-01" ... })
    yield from dbt.cli(dbt_args, context=context).stream()
