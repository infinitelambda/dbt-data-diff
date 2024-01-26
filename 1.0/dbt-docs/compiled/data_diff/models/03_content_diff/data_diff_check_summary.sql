

with dummy as (select 1 as col)

select
  cast(null as TEXT) as src_db
  , cast(null as TEXT) as src_schema
  , cast(null as TEXT) as src_table
  , cast(null as TEXT) as trg_db
  , cast(null as TEXT) as trg_schema
  , cast(null as TEXT) as trg_table
  , cast(null as TEXT) as column_name
  , cast(null as integer) as diff_count
  , cast(null as integer) as table_count
  , cast(null as float) as diff_feeded_rate
  , cast(null as float) as match_percentage
  , cast(null as timestamp) as last_data_diff_timestamp
  , cast(null as TEXT) as diff_run_id

from dummy

where 1 = 0