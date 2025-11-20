{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

select
    game_id,
    -- We use the ingestion date as the "Snapshot Date"
    ingestion_date as snapshot_date,
    user_rating,
    metacritic_score,
    ratings_count,
    playtime_hours
from {{ ref('stg_games') }}

{% if is_incremental() %}
    -- Only insert snapshots we haven't processed yet
    where ingestion_date > (select max(snapshot_date) from {{ this }})
{% endif %}
