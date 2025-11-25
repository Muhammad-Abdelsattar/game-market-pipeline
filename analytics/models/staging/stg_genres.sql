with source as ( select * from {{ source('rawg_lake', 'raw_genres') }} ),
flattened as (
    select {{ explode_json('results') }} as item,
    strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
)
select
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'item.id']) }} as genre_key,
    'RAWG' as source_system,
    item.id as genre_id,
    
    item.name as genre_name,
    item.slug as genre_slug,
    item.games_count,
    item.image_background,
    ingestion_date
from flattened
qualify row_number() over (partition by genre_id order by ingestion_date desc) = 1
