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
  , cast(null as {{ dbt.type_string() }}) as column_name -- string COMMENT 'The name of the column',
  , cast(null as {{ dbt.type_string() }}) as data_type -- string COMMENT 'The data type of the column',
  -- string COMMENT 'The percision in case of datetime data type',
  , cast(null as {{ dbt.type_string() }}) as datetime_precision
  -- string COMMENT 'The percision in case of numeric data type',
  , cast(null as {{ dbt.type_string() }}) as numeric_precision
  -- string COMMENT 'The scale in case of numeric data type',
  , cast(null as {{ dbt.type_string() }}) as numeric_scale
  -- boolean COMMENT 'true/false, where true means the column can be found both source and target table',
  , cast(null as {{ dbt.type_boolean() }}) as common_col
  -- string COMMENT 'values are common/source only/target only',
  , cast(null as {{ dbt.type_string() }}) as common_col_text
  -- boolean COMMENT 'true/false, where true means the column can be found only in source object',
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_src
  -- boolean COMMENT 'true/false, where true means the column can be found only in target object',
  , cast(null as {{ dbt.type_boolean() }}) as is_exclusive_trg
  -- boolean COMMENT 'true/false, where true means the data type is the same in both places',
  , cast(null as {{ dbt.type_boolean() }}) as datatype_check
  -- timestamp COMMENT 'Last modified timestamp'
  , cast(null as {{ dbt.type_timestamp() }}) as last_modified_timestamp

from dummy

where 1 = 0
