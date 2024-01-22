{% macro create_resources() -%}
  {{ return(adapter.dispatch('create_resources')()) }}
{%- endmacro %}

{% macro default__create_resources() -%}

  {{ log("[SCRIPT]: create_resources", info=True) if execute }}
  {{ data_diff.create__check_key() }}
  {{ data_diff.create__check_schema() }}
  {{ data_diff.create__check_data_diff() }}

{%- endmacro %}
