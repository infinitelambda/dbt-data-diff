

with dummy as (select 1 as col)

select
  cast(null as TEXT) as src_db
  , cast(null as TEXT) as src_schema
  , cast(null as TEXT) as src_table
  , cast(null as TEXT) as trg_db
  , cast(null as TEXT) as trg_schema
  , cast(null as TEXT) as trg_table
  , cast(null as TEXT) as column_name
  , cast(null as TEXT) as data_type
  , cast(null as TEXT) as datetime_precision
  , cast(null as TEXT) as numeric_precision
  , cast(null as TEXT) as numeric_scale
  , cast(null as boolean) as common_col
  , cast(null as TEXT) as common_col_text
  , cast(null as boolean) as is_exclusive_src
  , cast(null as boolean) as is_exclusive_trg
  , cast(null as boolean) as datatype_check
  , cast(null as timestamp) as last_data_diff_timestamp
  , cast(null as TEXT) as pipe_name
  , cast(null as TEXT) as diff_run_id

from dummy

where 1 = 0