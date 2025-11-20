with source as (
    select * from {{ source('rawg_lake', 'raw_games') }}
),

games_flattened as (
    select 
        {{ explode_json('results') }} as game,
        strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
),

platforms_flattened as (
    select
        game.id as game_id,
        {{ explode_json('game.platforms') }} as platform_wrapper, -- This is the wrapper object
        ingestion_date
    from games_flattened
    where game.platforms is not null
)

select 
    game_id,
    -- Access the nested 'platform' object inside the wrapper
    platform_wrapper.platform.id::int as platform_id,
    ingestion_date
from platforms_flattened
qualify row_number() over (partition by game_id, platform_id order by ingestion_date desc) = 1
