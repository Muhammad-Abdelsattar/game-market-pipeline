with source as (
    select 
        *
        -- EXPLICITLY SELECT FILENAME FOR SNOWFLAKE
        {% if target.type == 'snowflake' %}
        , metadata$filename as filename
        {% endif %}
    from {{ source('rawg_lake', 'raw_games') }}
),

flattened as (
    select
        {% if target.type == 'duckdb' %}
            unnest(results) as item,
        {% else %}
            flat.value as item,
        {% endif %}
        -- NOW WE CAN JUST USE 'filename' FOR BOTH
        {{ extract_ingestion_date('filename') }} as ingestion_date
    from source
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => results) as flat
    {% endif %}
)

select
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('item', 'id')]) }} as game_key,
    'RAWG' as source_system,
    {{ json_select('item', 'id') }}::int as game_id,
    {{ json_select('item', 'slug') }}::text as game_slug,
    {{ json_select('item', 'name') }}::text as game_name,
    {{ json_select('item', 'released') }}::date as release_date,
    {{ json_select('item', 'tba') }}::boolean as is_tba,
    {{ json_select('item', 'rating') }}::float as user_rating,
    {{ json_select('item', 'rating_top') }}::float as best_rating,
    {{ json_select('item', 'ratings_count') }}::int as ratings_count,
    {{ json_select('item', 'reviews_text_count') }}::int as reviews_text_count,
    {{ json_select('item', 'added') }}::int as added_to_libraries_count,
    {{ json_select('item', 'metacritic') }}::int as metacritic_score,
    {{ json_select('item', 'playtime') }}::int as playtime_hours,
    {{ json_select('item', 'updated') }}::timestamp as updated_at,
    {{ json_select('item', 'esrb_rating.name') }}::varchar as esrb_rating_name,
    ingestion_date
from flattened
qualify row_number() over (partition by game_id order by ingestion_date desc) = 1
