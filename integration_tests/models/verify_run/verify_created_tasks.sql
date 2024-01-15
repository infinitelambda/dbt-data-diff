{% set ns = data_diff.get_namespace() %}

{{
  config(
    materialized='table',
    sql_header='show tasks in schema ' ~ ns ~ ';'
  )
}}

{% set dag_log_entries = dbt_utils.get_column_values(
    table=ref('log_for_validation'),
    column="upper(trim(split(diff_type, ':')[1]))",
    where="diff_type ilike 'DAG%' and value is not null"
  ) or []
%}

with show_data as (

  select  *
  from    table(result_scan(last_query_id()))

)
{% if dag_log_entries | length == 0 %}

  select  'Normal run (non-async)' as test_case, count(*) as actual, 0 as expected
  from    show_data

{% else %}
  --Assuming data_diff__auto_pipe = true
  {% set configured_rows = var("data_diff__configured_tables", []) | length %}
  select  'key tasks' as test_case, count(*) as actual, {{ configured_rows }} as expected
  from    show_data
  where   "name" ilike '%check_key_%{{ dag_log_entries[0] }}%'

  union all

  select  'schema tasks' as test_case, count(*) as actual, {{ configured_rows }} as expected
  from    show_data
  where   "name" ilike '%check_schema_%{{ dag_log_entries[0] }}%'

  union all

  select  'data-diff tasks' as test_case, count(*) as actual, {{ configured_rows }} as expected
  from    show_data
  where   "name" ilike '%check_data_diff_%{{ dag_log_entries[0] }}%'

  union all

  select  'root task' as test_case, count(*) as actual, 1 as expected
  from    show_data
  where   "name" ilike '%task_root%{{ dag_log_entries[0] }}%'

  union all

  select  'end task' as test_case, count(*) as actual, 1 as expected
  from    show_data
  where   "name" ilike '%task_end%{{ dag_log_entries[0] }}%'

{% endif %}
