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
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'game_item.id']) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'publisher_id']) }} as publisher_key,
    ingestion_date
from games_flattened
qualify row_number() over (partition by game_key, publisher_key order by ingestion_date desc) = 1
