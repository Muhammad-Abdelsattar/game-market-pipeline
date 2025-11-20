with source as (
    select * from {{ source('rawg_lake', 'raw_publishers') }}
),

pubs_flattened as (
    select 
        {{ explode_json('results') }} as publisher,
        strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
),

games_flattened as (
    select
        publisher.id as publisher_id,
        {{ explode_json('publisher.games') }} as game_item,
        ingestion_date
    from pubs_flattened
    where publisher.games is not null
)

select 
    game_item.id::int as game_id,
    publisher_id,
    ingestion_date
from games_flattened
qualify row_number() over (partition by game_id, publisher_id order by ingestion_date desc) = 1
