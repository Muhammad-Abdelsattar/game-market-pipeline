{{ config(materialized='table') }}
select
    game_key,
    platform_key
from {{ ref('stg_game_platforms') }}
