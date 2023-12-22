{% macro get_namespace() %}

  {% set namespace -%}
    {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
  {%- endset %}

  {{ return(namespace) }}

{% endmacro %}
