{{ config(
    materialized='incremental',
    unique_key='publisher_key',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_publishers') }}
)

{% if is_incremental() %}
    , latest_checkpoint as (
        select max(ingestion_date) as max_date from {{ this }}
    )
{% endif %}

select
    publisher_key,
    publisher_id,
    publisher_name,
    publisher_slug,
    games_count,
    image_background,
    ingestion_date
from source

{% if is_incremental() %}
    where ingestion_date > (select max_date from latest_checkpoint)
{% endif %}
