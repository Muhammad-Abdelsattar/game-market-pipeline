with source as ( select * from {{ source('rawg_lake', 'raw_games') }} ),
games_flattened as (
    select {{ explode_json('results') }} as game,
    strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
),
genres_flattened as (
    select
        game.id as game_id,
        {{ explode_json('game.genres') }} as genre_item,
        ingestion_date
    from games_flattened
    where game.genres is not null
)
select 
    -- Generate Keys
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'game_id']) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'genre_item.id']) }} as genre_key,
    
    game_id,
    genre_item.id::int as genre_id,
    ingestion_date
from genres_flattened
qualify row_number() over (partition by game_id, genre_id order by ingestion_date desc) = 1
