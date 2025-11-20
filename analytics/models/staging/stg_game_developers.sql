with source as (
    select * from {{ source('rawg_lake', 'raw_developers') }}
),

devs_flattened as (
    select 
        {{ explode_json('results') }} as developer,
        strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
),

games_flattened as (
    select
        developer.id as developer_id,
        {{ explode_json('developer.games') }} as game_item,
        ingestion_date
    from devs_flattened
    where developer.games is not null
)

select 
    game_item.id::int as game_id, -- The Game ID is inside the nested object
    developer_id,
    ingestion_date
from games_flattened
qualify row_number() over (partition by game_id, developer_id order by ingestion_date desc) = 1
