{% macro data_diff__run_async(in_hook=false) -%}

  --ONLY IDEA / NOT IMPLEMENTATED!
  {% set namespace -%}
    {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
  {%- endset %}

  {% set query -%}

    --create_check_key_tasks(root="data_diff__task_check_key");
    --create_check_schema_tasks(root="data_diff__task_check_schema");
    --create_check_data_diff_tasks(root="data_diff__task_check_data_diff");

    execute task {{ namespace }}.data_diff__task_check_key;
    execute task {{ namespace }}.data_diff__task_check_schema;
    execute task {{ namespace }}.data_diff__task_check_data_diff;

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__run_async", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__run_async", info=True) }}
    {% set results = run_query(query) %}
    {{ log(results, info=True) }}
  {% endif %}

{%- endmacro %}
