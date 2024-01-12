

with dummy as (select 1 as col)

select
  cast(null as TEXT) as src_db
  , cast(null as TEXT) as src_schema
  , cast(null as TEXT) as src_table
  , cast(null as TEXT) as trg_db
  , cast(null as TEXT) as trg_schema
  , cast(null as TEXT) as trg_table
  , cast(null as TEXT) as pk
  , cast(null as array) as include_columns
  , cast(null as array) as exclude_columns
  , cast(null as TEXT) as where_condition
  , cast(null as boolean) as is_enabled
  , cast(null as TEXT) as pipe_name

from dummy

where 1 = 0