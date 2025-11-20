{{ config(materialized='table') }}
select
    game_id,
    publisher_id
from {{ ref('stg_game_publishers') }}
