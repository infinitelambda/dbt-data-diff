{% macro data_diff__run_async(in_hook=false) -%}

  {% set namespace = data_diff.get_namespace() %}

  {% set root_task__check_key = "data_diff__task_root__check_key" %}
  {% set root_task__check_schema = "data_diff__task_root__check_schema" %}
  {% set root_task__check_data_diff = "data_diff__task_root__check_data_diff" %}
  {% set prefix_batch_task__check_key = "data_diff__task__check_key_batch_" %}
  {% set prefix_batch_task__check_schema = "data_diff__task__check_schema_batch_" %}
  {% set prefix_batch_task__check_data_diff = "data_diff__task__check_data_diff_batch_" %}

  {% set batches = dbt_utils.get_column_values(table=ref('configured_tables'), column='batch') %}

  {% set query -%}
    --1. Build the DAG
    create or replace task {{ namespace }}.{{ root_task__check_key }}
      warehouse = {{ target.warehouse }}
      as
      select sysdate() as run_time;
    --
    create or replace task {{ namespace }}.{{ root_task__check_schema }}
      warehouse = {{ target.warehouse }}
      as
      select sysdate() as run_time;
    --
    create or replace task {{ namespace }}.data_diff__task_root__check_data_diff
      warehouse = {{ target.warehouse }}
      as
      select sysdate() as end_time;

    {% for batch_id in batches %}
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ root_task__check_key }}
        as
        call {{ namespace }}.check_key('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }} resume;

      --
      alter task {{ namespace }}.{{ root_task__check_schema }} add after {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }};
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ root_task__check_schema }}
        as
        call {{ namespace }}.check_schema('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }} resume;

      --
      alter task {{ namespace }}.{{ root_task__check_data_diff }} add after {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }};
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_data_diff }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ root_task__check_data_diff }}
        as
        call {{ namespace }}.check_data_diff('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_data_diff }}{{ batch_id }} resume;

    {%- endfor %}
    alter task {{ namespace }}.{{ root_task__check_schema }} resume;
    alter task {{ namespace }}.{{ root_task__check_data_diff }} resume;

    --2. Execute root task
    execute task {{ namespace }}.{{ root_task__check_key }};

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__run_async", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__run_async", info=True) }}
    {% set results = run_query(query) %}
    {{ log(results, info=True) }}
    {{ log(
        (
          "👉 Visit: "
          "https://SF_BASE_URL/#/data/"
          "databases/" ~ (generate_database_name(var("data_diff__database", target.database)) | upper) ~ "/"
          "schemas/" ~ (generate_schema_name(var("data_diff__schema", target.schema)) | upper) ~ "/"
          "task/" ~ (root_task__check_key | upper) ~ "/"
          "graph"
          " to monitor the DAG execution..."
        ),
        info=True
      )
    }}

  {% endif %}

{%- endmacro %}
