{% macro create_resources(args) -%}

  {{ log("[SCRIPT]: create_resources", info=True) if execute }}
  {{ data_diff.create__check_key(args) }}
  {{ data_diff.create__check_schema(args) }}
  {{ data_diff.create__check_data_diff(args) }}

{%- endmacro %}
