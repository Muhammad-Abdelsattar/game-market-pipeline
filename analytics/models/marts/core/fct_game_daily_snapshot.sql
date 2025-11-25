{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

select 
    -- The Foreign Key to the Game entity
    game_key,
    
    -- The Snapshot Date (When we saw this data)
    ingestion_date as snapshot_date,
    
    -- A unique ID for this specific snapshot row
    -- Useful if you need to reference this specific day's record elsewhere
    {{ dbt_utils.generate_surrogate_key(['game_key', 'ingestion_date']) }} as snapshot_id,
    
    source_system,
    user_rating,
    metacritic_score,
    ratings_count,
    playtime_hours

from {{ ref('stg_games') }}

{% if is_incremental() %}
  -- Only insert snapshots for days we haven't processed yet
  where ingestion_date > (select max(snapshot_date) from {{ this }})
{% endif %}
