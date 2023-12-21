{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
    materialized = 'incremental',
    on_schema_change = 'append_new_columns',
    full_refresh = var('data_diff__full_refresh', false),
    alias = var("data_diff__log_for_validation__alias", this.name)
  )
}}

with dummy as (select 1 as col)

select
  cast(null as {{ dbt.type_timestamp() }}) as start_time
  , cast(null as {{ dbt.type_timestamp() }}) as end_time
  , cast(null as {{ dbt.type_string() }}) as sql_statement
  , cast(null as {{ dbt.type_string() }}) as diff_type

from dummy

where 1 = 0
