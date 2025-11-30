with source as ( 
    select 
        * 
        -- EXPLICITLY SELECT FILENAME FOR SNOWFLAKE
        {% if target.type == 'snowflake' %}
        , metadata$filename as filename
        {% endif %}
    from {{ source('rawg_lake', 'raw_platforms') }} 
),
flattened as (
    select
        {% if target.type == 'duckdb' %}
            unnest(results) as item,
        {% else %}
            flat.value as item,
        {% endif %}
        -- USE 'filename' FOR BOTH
        {{ extract_ingestion_date('filename') }} as ingestion_date
    from source
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => results) as flat
    {% endif %}
)
select
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('item', 'id')]) }} as platform_key,
    'RAWG' as source_system,
    {{ json_select('item', 'id') }}::int as platform_id,
    
    {{ json_select('item', 'name') }}::text as platform_name,
    {{ json_select('item', 'slug') }}::text as platform_slug,
    {{ json_select('item', 'games_count') }}::int as games_count,
    {{ json_select('item', 'image_background') }}::text as image_background,
    {{ json_select('item', 'year_start') }}::int as year_start,
    {{ json_select('item', 'year_end') }}::int as year_end,
    ingestion_date
from flattened
qualify row_number() over (partition by platform_id order by ingestion_date desc) = 1
