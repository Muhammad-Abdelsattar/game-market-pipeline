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
genres_flattened as (
    select
        {{ json_select('game', 'id') }} as game_id,
        {% if target.type == 'duckdb' %}
            unnest(game.genres) as genre_item,
        {% else %}
            flat_genres.value as genre_item,
        {% endif %}
        ingestion_date
    from games_flattened
    {% if target.type == 'snowflake' %}
        , lateral flatten(input => game:genres) as flat_genres
    {% endif %}
    where 
    {{ json_select('game', 'genres') }} is not null
)
select 
    -- Generate Keys
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", 'game_id']) }} as game_key,
    {{ dbt_utils.generate_surrogate_key(["'RAWG'", json_select('genre_item', 'id')]) }} as genre_key,
    
    game_id::int as game_id,
    {{ json_select('genre_item', 'id') }}::int as genre_id,
    ingestion_date
from genres_flattened
qualify row_number() over (partition by game_id, genre_id order by ingestion_date desc) = 1
