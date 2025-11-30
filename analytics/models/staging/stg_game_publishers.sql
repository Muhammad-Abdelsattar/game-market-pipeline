with source as ( 
    select 
        * 
        -- EXPLICITLY SELECT FILENAME FOR SNOWFLAKE
        {% if target.type == 'snowflake' %}
        , metadata$filename as filename
        {% endif %}
    from {{ source('rawg_lake', 'raw_publishers') }} 
),

pubs_flattened as (
    select 
        {% if target.type == 'duckdb' %}
            unnest(results) as publisher,
        {% else %}
            flat.value as publisher,
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
        {{ json_select('publisher', 'id') }} as publisher_id,
        {% if target.type == 'duckdb' %}
            unnest(publisher.games) as game_item,
        {% else %}
            flat_games.value as game_item,
        {% endif %}
        ingestion_date
    from pubs_flattened
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => publisher:games) as flat_games
    {% endif %}
    where 
    {{ json_select('publisher', 'games') }} is not null
)
select 
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('game_item', 'id')]) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'publisher_id']) }} as publisher_key,
    ingestion_date
from games_flattened
qualify row_number() over (partition by game_key, publisher_key order by ingestion_date desc) = 1
