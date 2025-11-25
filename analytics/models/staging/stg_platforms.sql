with source as ( select * from {{ source('rawg_lake', 'raw_platforms') }} ),
flattened as (
    select {{ explode_json('results') }} as item,
    strptime(regexp_extract(filename, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d') as ingestion_date
    from source
)
select
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'item.id']) }} as platform_key,
    'RAWG' as source_system,
    item.id as platform_id,
    
    item.name as platform_name,
    item.slug as platform_slug,
    item.games_count,
    item.image_background,
    item.year_start,
    item.year_end,
    ingestion_date
from flattened
qualify row_number() over (partition by platform_id order by ingestion_date desc) = 1
