{% macro load_all_raw_data() %}

    {# Define the mapping of Table Name -> S3 Folder #}
    {% set load_config = [
        {'table': 'RAW_GAMES',      's3_path': 'games'},
        {'table': 'RAW_GENRES',     's3_path': 'genres'},
        {'table': 'RAW_DEVELOPERS', 's3_path': 'developers'},
        {'table': 'RAW_PLATFORMS',  's3_path': 'platforms'},
        {'table': 'RAW_PUBLISHERS', 's3_path': 'publishers'}
    ] %}

    {# Loop through each config and run the COPY command #}
    {% for item in load_config %}
        
        {% set table_name = item.table %}
        {% set s3_path = item.s3_path %}

        {{ print("Loading data into " ~ table_name ~ " from " ~ s3_path ~ "...") }}

        {% set query %}
            COPY INTO GAME_MARKET_DB.RAW.{{ table_name }} (data, filename)
            FROM (
                SELECT $1, METADATA$FILENAME 
                -- The stage in Terraform points to /raw/, so we append the folder here
                FROM @GAME_MARKET_DB.RAW.GAME_MARKET_STAGE/{{ s3_path }}/
            )
            FILE_FORMAT = (FORMAT_NAME = 'GAME_MARKET_DB.RAW.JSON_FORMAT')
            ON_ERROR = SKIP_FILE
            -- FORCE=TRUE reloads files even if they haven't changed (good for testing)
            FORCE = TRUE;
        {% endset %}

        {# Execute the query #}
        {% do run_query(query) %}
        
        {{ print("Successfully loaded " ~ table_name) }}

    {% endfor %}

{% endmacro %}
