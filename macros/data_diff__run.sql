{% macro data_diff__run(in_hook=false, is_cleanup=false) -%}

  {% set namespace = data_diff.get_namespace() %}

  {% set query -%}

    call {{ namespace }}.check_key('', '{{ invocation_id }}');
    call {{ namespace }}.check_schema('', '{{ invocation_id }}');
    call {{ namespace }}.check_data_diff('', '{{ invocation_id }}');

    {% if is_cleanup -%}
      {{ data_diff.data_diff__cleanup(in_hook=true) }}
    {%- endif %}

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
