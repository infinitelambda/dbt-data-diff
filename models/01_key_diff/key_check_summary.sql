{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
  )
}}

select
  src_db
  , src_schema
  , src_table
  , trg_db
  , trg_schema
  , trg_table
  , pk
  , last_data_diff_timestamp
  , sum(case when is_exclusive_src then 1 else 0 end) as number_of_exclusive_src
  , sum(case when is_exclusive_trg then 1 else 0 end) as number_of_exclusive_trg
  , sum(case when is_diff_unique_key then 1 else 0 end) as number_of_diff_pk

from {{ ref('key_check') }}

group by all

qualify row_number() over (
  partition by src_db, src_schema, src_table, trg_db, trg_schema, trg_table
  order by last_data_diff_timestamp desc
) = 1
