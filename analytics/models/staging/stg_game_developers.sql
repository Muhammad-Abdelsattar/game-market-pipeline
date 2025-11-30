with source as ( 
    select 
        * 
        -- EXPLICITLY SELECT FILENAME FOR SNOWFLAKE
        {% if target.type == 'snowflake' %}
        , metadata$filename as filename
        {% endif %}
    from {{ source('rawg_lake', 'raw_developers') }} 
),

devs_flattened as (
    select
        {% if target.type == 'duckdb' %}
            unnest(results) as developer,
        {% else %}
            flat.value as developer,
        {% endif %}
        -- USE 'filename' FOR BOTH
        {{ extract_ingestion_date('filename') }} as ingestion_date
    from source
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => results) as flat
    {% endif %}
),

games_flattened as (
    select
        {{ json_select('developer', 'id') }}::int as developer_id,
        {% if target.type == 'duckdb' %}
            unnest(developer.games) as game_item,
        {% else %}
            flat_games.value as game_item,
        {% endif %}
        ingestion_date
    from devs_flattened
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => developer:games) as flat_games
    {% endif %}
    where 
    {{ json_select('developer', 'games') }} is not null
)

select 
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('game_item', 'id')]) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'developer_id']) }} as developer_key,
    
    {{ json_select('game_item', 'id') }}::int as game_id,
    developer_id,
    ingestion_date
from games_flattened
qualify row_number() over (partition by game_id, developer_id order by ingestion_date desc) = 1
