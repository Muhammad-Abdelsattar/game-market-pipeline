{{ config(materialized='table') }}
select
    game_id,
    genre_id
from {{ ref('stg_game_genres') }}
