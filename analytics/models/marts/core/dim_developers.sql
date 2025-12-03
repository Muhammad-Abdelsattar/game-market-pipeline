{{ config(
    materialized='incremental',
    unique_key='developer_id', 
    incremental_strategy='merge'
) }}
with source as (select * from {{ ref('stg_developers') }})

{% if is_incremental() %}
    , latest_checkpoint as (
        select max(ingestion_date) as max_date from {{ this }}
    )
{% endif %}

select
    developer_key, -- Primary Key
    source_system,
    developer_id,  -- Natural Key (Keep for reference)
    developer_name,
    developer_slug,
    games_count,
    image_background,
    ingestion_date
from source

{% if is_incremental() %}
    where ingestion_date > (select max_date from latest_checkpoint)
{% endif %}
