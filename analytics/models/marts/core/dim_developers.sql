{{ config(
    materialized='incremental',
    unique_key='developer_id',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_developers') }}
)

-- Only define this CTE if we are in incremental mode
{% if is_incremental() %}
    , latest_checkpoint as (
        select max(ingestion_date) as max_date from {{ this }}
    )
{% endif %}

select
    developer_id,
    developer_name,
    developer_slug,
    games_count,
    image_background,
    ingestion_date
from source

{% if is_incremental() %}
    -- Select from the CTE we defined above
    where ingestion_date > (select max_date from latest_checkpoint)
{% endif %}
