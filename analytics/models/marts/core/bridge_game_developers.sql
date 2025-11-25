{{ config(materialized='table') }}
select
    game_key,
    developer_key
from {{ ref('stg_game_developers') }}
