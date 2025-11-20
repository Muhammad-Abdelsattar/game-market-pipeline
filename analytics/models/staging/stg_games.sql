with source as (
    select * from {{ source('rawg_lake', 'raw_games') }}
),

flattened as (
    select
        {{ explode_json('results') }} as item,
        strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
)

select
    item.id as game_id,
    item.slug as game_slug,
    item.name as game_name,
    item.released::date as release_date,
    item.tba::boolean as is_tba,
    item.rating as user_rating,
    item.rating_top as best_rating,
    item.ratings_count,
    item.reviews_text_count,
    item.added as added_to_libraries_count,
    item.metacritic as metacritic_score,
    item.playtime as playtime_hours,
    item.updated as updated_at,
    
    -- Handling nested object (ESRB can be null)
    try_cast(item.esrb_rating.name as varchar) as esrb_rating_name,
    
    ingestion_date
from flattened
qualify row_number() over (partition by game_id order by ingestion_date desc) = 1
