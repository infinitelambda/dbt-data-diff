{% macro data_diff__run(in_hook=false) -%}

  {% set namespace -%}
    {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
  {%- endset %}

  {% set query -%}

    call {{ namespace }}.check_key();
    call {{ namespace }}.check_schema();
    call {{ namespace }}.check_data_diff();

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__run", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__run", info=True) }}
    {% set results = run_query(query) %}
    {{ log("Completed", info=True) }}
  {% endif %}

{%- endmacro %}
