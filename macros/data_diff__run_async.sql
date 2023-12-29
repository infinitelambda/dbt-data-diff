{% macro data_diff__run_async(in_hook=false, is_cleanup=false) -%}

  {% set namespace = data_diff.get_namespace() %}
  {% set dbt_invocation_id = invocation_id | replace("-", "_") %}

  {% set root_task = "data_diff__task_root_" ~ dbt_invocation_id %}
  {% set end_task = "data_diff__task_end_" ~ dbt_invocation_id %}
  {% set prefix_batch_task__check_key = "data_diff__task__check_key_batch_" ~ dbt_invocation_id ~ "_" %}
  {% set prefix_batch_task__check_schema = "data_diff__task__check_schema_batch_" ~ dbt_invocation_id ~ "_" %}
  {% set prefix_batch_task__check_data_diff = "data_diff__task__check_data_diff_batch_" ~ dbt_invocation_id ~ "_" %}

  {% set batches = dbt_utils.get_column_values(table=ref('configured_tables'), column='pipe_name') %}
  {% set log_model_fdn -%} {{ ref("log_for_validation") }} {%- endset %}

  {% set query -%}
    --1. Build the DAG
    --root task
    create or replace task {{ namespace }}.{{ root_task }}
      warehouse = {{ target.warehouse }}
      as
      insert into {{ log_model_fdn }} (start_time, end_time, sql_statement, diff_type)
        values (sysdate(), null, null, 'start: task dag of {{ dbt_invocation_id }}');
    --end task
    create or replace task {{ namespace }}.{{ end_task }}
      warehouse = {{ target.warehouse }}
      as
      insert into {{ log_model_fdn }} (start_time, end_time, sql_statement, diff_type)
        values (sysdate(), null, null, 'end: task dag of {{ dbt_invocation_id }}');

    {% for batch_id in batches %}

      --key task(s)
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ root_task }}
        as
        call {{ namespace }}.check_key('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }} resume;

      --schema task(s): run after key check
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ prefix_batch_task__check_key }}{{ batch_id }}
        as
        call {{ namespace }}.check_schema('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }} resume;

      --data diff task(s): run after schema task & depends on its result
      create or replace task {{ namespace }}.{{ prefix_batch_task__check_data_diff }}{{ batch_id }}
        warehouse = {{ target.warehouse }}
        after {{ namespace }}.{{ prefix_batch_task__check_schema }}{{ batch_id }}
        as
        call {{ namespace }}.check_data_diff('{{ batch_id }}');
      alter task {{ namespace }}.{{ prefix_batch_task__check_data_diff }}{{ batch_id }} resume;

      --end task
      alter task {{ namespace }}.{{ end_task }} add after {{ namespace }}.{{ prefix_batch_task__check_data_diff }}{{ batch_id }};

    {%- endfor %}
    alter task {{ namespace }}.{{ end_task }} resume;

    --2. Execute root task
    execute task {{ namespace }}.{{ root_task }};

    --Clean up
    {% if is_cleanup -%}
      {{ data_diff.data_diff__cleanup(in_hook=true, p_invocation_id=dbt_invocation_id) }}
    {%- endif %}

  {%- endset %}

  {% if in_hook %}
    {{ log("[SCRIPT]: data_diff__run_async", info=True) if execute }}
    {{ return(query) }}
  {% else %}
    {{ log("[RUN]: data_diff__run_async", info=True) }}
    {% set results = run_query(query) %}
    {{ log(results, info=True) }}
  {% endif %}

  {{ log(
      (
        "👉 Visit the root task at: "
        "https://{SF_BASE_URL}/#/data/"
        "databases/" ~ (generate_database_name(var("data_diff__database", target.database)) | upper) ~ "/"
        "schemas/" ~ (generate_schema_name(var("data_diff__schema", target.schema)) | upper) ~ "/"
        "task/" ~ (root_task | upper) ~ "/"
        "graph"
        " to monitor the DAG execution..."
      ),
      info=True
    )
  }}
  {{ log("💡 Poll status of " ~ (end_task | upper) ~ " to know if the DAG finished", info=True) }}

{%- endmacro %}
