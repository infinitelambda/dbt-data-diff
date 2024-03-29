{% macro data_diff__cleanup(in_hook=false, p_invocation_id=none) -%}
  {{ return(adapter.dispatch('data_diff__cleanup')(in_hook=in_hook, p_invocation_id=p_invocation_id)) }}
{%- endmacro %}

{% macro default__data_diff__cleanup(in_hook=false, p_invocation_id=none) -%}

  {% set namespace = data_diff.get_namespace() %}

  {% set query -%}

    TODO: clean up log table - keep today data
    TODO: clean up DAG tasks - keep invocation_id passed in & delete others, none for doing nothing

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__cleanup", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__cleanup", info=True) }}
    {% set results = run_query(query) %}
    {{ log(results.rows, info=True) }}
  {% endif %}

{%- endmacro %}
