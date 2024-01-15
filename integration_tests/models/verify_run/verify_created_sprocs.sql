{% set ns = data_diff.get_namespace() %}

{{
  config(
    materialized='table',
    sql_header='show procedures in schema ' ~ ns ~ ';'
  )
}}

{% set sproc_names = [
  "check_data_diff",
  "check_key",
  "check_schema",
] %}

with show_data as (

  select  *
  from    table(result_scan(last_query_id()))
  where   "description" = 'user-defined procedure'

)
{% for item in sproc_names %}

  select  upper(concat("catalog_name",'.',"schema_name",'.',"name")) as actual
          ,upper('{{ ns }}.{{ item }}') as expected
  from    show_data
  where   "name" ilike '{{ item }}'
  {% if not loop.last %} union all {% endif %}

{% endfor %}
