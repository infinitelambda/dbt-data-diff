{% macro data_diff__cleanup(in_hook=false) -%}

  {% set namespace -%}
    {{ var("data_diff__database", target.database) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
  {%- endset %}

  {% set query -%}

    TODO

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__cleanup", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__cleanup", info=True) }}
    {% set results = run_query(query) %}
    {{ log(results, info=True) }}
  {% endif %}

{%- endmacro %}
