with source as ( 
    select 
        * 
        -- EXPLICITLY SELECT FILENAME FOR SNOWFLAKE
        {% if target.type == 'snowflake' %}
        , metadata$filename as filename
        {% endif %}
    from {{ source('rawg_lake', 'raw_games') }} 
),

games_flattened as (
    select 
        {% if target.type == 'duckdb' %}
            unnest(results) as game,
        {% else %}
            flat.value as game,
        {% endif %}
        -- USE 'filename' FOR BOTH
        {{ extract_ingestion_date('filename') }} as ingestion_date
    from source
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => results) as flat
    {% endif %}
),

platforms_flattened as (
    select
        {{ json_select('game', 'id') }} as game_id,
        {% if target.type == 'duckdb' %}
            unnest(game.platforms) as platform_wrapper, -- This is the wrapper object
        {% else %}
            flat_platforms.value as platform_wrapper,
        {% endif %}
        ingestion_date
    from games_flattened
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => game:platforms) as flat_platforms
    {% endif %}
    where 
    {{ json_select('game', 'platforms') }} is not null
)
select 
    -- Generate BOTH keys so they can join to their respective dimensions
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'game_id']) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('platform_wrapper', 'platform.id')]) }} as platform_key,
    
    ingestion_date
from platforms_flattened
qualify row_number() over (partition by game_id, platform_key order by ingestion_date desc) = 1
