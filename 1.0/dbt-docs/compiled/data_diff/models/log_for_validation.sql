

with dummy as (select 1 as col)

select
  cast(null as timestamp) as start_time
  , cast(null as timestamp) as end_time
  , cast(null as TEXT) as sql_statement
  , cast(null as timestamp) as diff_start_time
  , cast(null as TEXT) as diff_type

from dummy

where 1 = 0