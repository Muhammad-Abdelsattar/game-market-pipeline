{{ config(materialized='table') }}
select
    platform_key,
    source_system,
    platform_id,
    platform_name,
    platform_slug,
    year_start,
    year_end
from {{ ref('stg_platforms') }}
