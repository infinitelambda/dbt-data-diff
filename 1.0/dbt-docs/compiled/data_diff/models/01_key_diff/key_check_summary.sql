

select
  src_db
  , src_schema
  , src_table
  , trg_db
  , trg_schema
  , trg_table
  , pk
  , last_data_diff_timestamp
  , diff_run_id
  , sum(case when is_exclusive_src then 1 else 0 end) as number_of_exclusive_src
  , sum(case when is_exclusive_trg then 1 else 0 end) as number_of_exclusive_trg
  , sum(case when is_diff_unique_key then 1 else 0 end) as number_of_diff_pk

from data_diff.DOCS_datadiff.key_check

group by all