{{ config(
    materialized='incremental',
    unique_key='game_id',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_games') }}
)

{% if is_incremental() %}
    , latest_checkpoint as (
        select max(last_loaded_at) as max_date from {{ this }}
    )
{% endif %}

select
    game_id,
    game_name,
    game_slug,
    release_date,
    esrb_rating_name,
    user_rating,
    metacritic_score,
    ratings_count,
    playtime_hours,
    updated_at,
    ingestion_date as last_loaded_at
from source

{% if is_incremental() %}
    where ingestion_date > (select max_date from latest_checkpoint)
{% endif %}
