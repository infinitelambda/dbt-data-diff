{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
    materialized = 'incremental',
    on_schema_change = 'append_new_columns',
    full_refresh = var('data_diff__full_refresh', false),
    alias = var("data_diff__configured_tables__alias", this.name)
  )
}}

with dummy as (select 1 as col)

select
  cast(null as {{ dbt.type_string() }}) as src_db
  , cast(null as {{ dbt.type_string() }}) as src_schema
  , cast(null as {{ dbt.type_string() }}) as src_table
  , cast(null as {{ dbt.type_string() }}) as trg_db
  , cast(null as {{ dbt.type_string() }}) as trg_schema
  , cast(null as {{ dbt.type_string() }}) as trg_table
  , cast(null as {{ dbt.type_string() }}) as pk
  , cast(null as array) as include_columns
  , cast(null as array) as exclude_columns
  , cast(null as {{ dbt.type_boolean() }}) as is_enabled
  , cast(null as {{ dbt.type_string() }}) as pipe_name

from dummy

where 1 = 0
