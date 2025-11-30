{% macro json_select(table_alias, path) %}
    {# 
       Adapts JSON path selection for DuckDB (structs) vs Snowflake (variants).
       Usage: {{ json_select('item', 'id') }} 
       Usage Nested: {{ json_select('item', 'esrb_rating.name') }} 
    #}
    {% if target.type == 'duckdb' %}
        {{ table_alias }}.{{ path }}
    {% else %}
        {# Replace dot notation with colon notation for Snowflake #}
        {{ table_alias }}:{{ path | replace(".", ":") }}
    {% endif %}
{% endmacro %}
