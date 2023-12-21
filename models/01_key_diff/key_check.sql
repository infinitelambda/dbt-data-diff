{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
    materialized = 'incremental',
    on_schema_change = 'append_new_columns',
    full_refresh = var('data_diff__full_refresh', false)
  )
}}

with dummy as (select 1 as col)

select
  -- string COMMENT 'The database name of the source object to be compared',
  cast(null as {{ dbt.type_string() }}) as src_db
  -- string COMMENT 'The schema name of the source object to be compared',
  , cast(null as {{ dbt.type_string() }}) as src_schema
  -- string COMMENT 'The source object name to be compared',
  , cast(null as {{ dbt.type_string() }}) as src_table
  -- string COMMENT 'The database name of the target object to be compared',
  , cast(null as {{ dbt.type_string() }}) as trg_db
  -- string COMMENT 'The schema name of the target object to be compared',
  , cast(null as {{ dbt.type_string() }}) as trg_schema
  -- string COMMENT 'The target object to be compared',
  , cast(null as {{ dbt.type_string() }}) as trg_table
  -- string COMMENT 'The primary key of the objects to be compared',
  , cast(null as {{ dbt.type_string() }}) as pk
  -- string COMMENT 'The value of the primary key',
  , cast(null as {{ dbt.type_string() }}) as key_value
  -- boolean COMMENT 'true/false, where true means the key can be found only in the source object',
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_src
  -- boolean COMMENT 'true/false, where true means the key can be found only in the target object',
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_trg
  -- boolean COMMENT 'true/false, where true means the key is missing from the source or target object',
  , cast(null as {{ dbt.type_boolean() }}) as is_diff_unique_key
  -- timestamp COMMENT 'Last modified timestamp'
  , cast(null as {{ dbt.type_timestamp() }}) as last_modified_timestamp

from dummy

where 1 = 0
