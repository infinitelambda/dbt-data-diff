{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
    materialized = 'incremental',
    on_schema_change = 'append_new_columns',
    full_refresh = var('data_diff__full_refresh', false),
    alias = var("data_diff__schema_check__alias", this.name)
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
  , cast(null as {{ dbt.type_string() }}) as column_name
  , cast(null as {{ dbt.type_string() }}) as data_type
  , cast(null as {{ dbt.type_string() }}) as datetime_precision
  , cast(null as {{ dbt.type_string() }}) as numeric_precision
  , cast(null as {{ dbt.type_string() }}) as numeric_scale
  , cast(null as {{ dbt.type_boolean() }}) as common_col
  , cast(null as {{ dbt.type_string() }}) as common_col_text
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_src
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_trg
  , cast(null as {{ dbt.type_boolean() }}) as datatype_check
  , cast(null as {{ dbt.type_timestamp() }}) as last_data_diff_timestamp
  , cast(null as {{ dbt.type_string() }}) as pipe_name

from dummy

where 1 = 0
