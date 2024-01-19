

with dummy as (select 1 as col)

select
  cast(null as TEXT) as src_db
  , cast(null as TEXT) as src_schema
  , cast(null as TEXT) as src_table
  , cast(null as TEXT) as trg_db
  , cast(null as TEXT) as trg_schema
  , cast(null as TEXT) as trg_table
  , cast(null as TEXT) as pk
  , cast(null as TEXT) as key_value
  , cast(null as boolean) as is_exclusive_src
  , cast(null as boolean) as is_exclusive_trg
  , cast(null as boolean) as is_diff_unique_key
  , cast(null as timestamp) as last_data_diff_timestamp
  , cast(null as TEXT) as diff_run_id

from dummy

where 1 = 0