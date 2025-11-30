{% macro refresh_external_tables() %}
    {% if target.type == 'snowflake' %}
        {% set tables = [
            'RAW_GAMES',
            'RAW_GENRES',
            'RAW_DEVELOPERS',
            'RAW_PUBLISHERS',
            'RAW_PLATFORMS'
        ] %}

        {% for table in tables %}
            {% set query %}
                ALTER EXTERNAL TABLE RAW.{{ table }} REFRESH
            {% endset %}
            
            {% do run_query(query) %}
            {{ log("Refreshed external table: " ~ table, info=True) }}
        {% endfor %}
    {% endif %}
{% endmacro %}
