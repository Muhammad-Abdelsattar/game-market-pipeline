{{ config(materialized='table') }}
select
    genre_key,
    genre_id,
    genre_name,
    genre_slug,
    games_count,
    image_background
from {{ ref('stg_genres') }}
