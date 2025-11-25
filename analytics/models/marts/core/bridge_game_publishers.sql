{{ config(materialized='table') }}
select
    game_key,
    publisher_key
from {{ ref('stg_game_publishers') }}
