{{ config(materialized='table') }}
select
    game_id,
    developer_id
from {{ ref('stg_game_developers') }}
