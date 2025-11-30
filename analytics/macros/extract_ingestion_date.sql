{% macro extract_ingestion_date(column_name) %}
    {% if target.type == 'duckdb' %}
        strptime(regexp_extract({{ column_name }}, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1), '%Y-%m-%d')
    {% else %}
        TO_DATE(REGEXP_SUBSTR({{ column_name }}, 'run_date=([0-9]{4}-[0-9]{2}-[0-9]{2})', 1, 1, 'e', 1), 'YYYY-MM-DD')
    {% endif %}
{% endmacro %}
