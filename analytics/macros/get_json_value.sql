{% macro get_json_value(json_column, key_path) %}

    {# Adapter Logic: Check which database we are running on #}
  
    {% if target.type == 'duckdb' %}
    {# DuckDB Implementation #}
    json_extract_string({{ json_column }}, '$.{{ key_path }}')

  {% elif target.type == 'snowflake' %}
    {# Snowflake Implementation #}
    {# We assume the column is a VARIANT type #}
    {{ json_column }}:{{ key_path }}::STRING

  {% elif target.type == 'databricks' or target.type == 'spark' %}
    {# Databricks Implementation #}
    get_json_object({{ json_column }}, '$.{{ key_path }}')

  {% else %}
    {# Fallback (Postgres, etc) #}
    {{ json_column }}->>'{{ key_path }}'

  {% endif %}

{% endmacro %}
