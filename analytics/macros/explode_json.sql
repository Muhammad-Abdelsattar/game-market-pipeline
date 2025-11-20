{% macro explode_json(column_name) %}
    {# 
       DuckDB uses 'unnest()'. 
       Snowflake uses 'lateral flatten()'.
       Since strict SQL structure differs (SELECT vs FROM), 
       this macro focuses on the DuckDB implementation for your local dev.
    #}
    {% if target.type == 'duckdb' %}
        unnest({{ column_name }})
    {% else %}
        -- Snowflake fallback (Note: usually requires changing the FROM clause)
        flatten(input => {{ column_name }}) 
    {% endif %}
{% endmacro %}
