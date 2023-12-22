{% macro data_diff__run(in_hook=false) -%}

  {% set namespace = data_diff.get_namespace() %}

  {% set query -%}

    call {{ namespace }}.check_key('');
    call {{ namespace }}.check_schema('');
    call {{ namespace }}.check_data_diff('');

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
