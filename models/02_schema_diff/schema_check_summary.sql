{{
  config(
    database = var('data_diff__database', target.database),
    schema = var("data_diff__schema", target.schema),
    alias = var("data_diff__schema_check_summary__alias", this.name)
  )
}}

select
  src_db
  , src_schema
  , src_table
  , trg_db
  , trg_schema
  , trg_table
  , last_data_diff_timestamp
  , count(*) as number_of_columns
  , sum(case when common_col then 1 else 0 end) as mutual_columns
  , sum(case when is_exclusive_src then 1 else 0 end) as number_of_exclusive_target
  , listagg(
    case when is_exclusive_src then column_name end, ', '
  ) within group (order by column_name) as exclusive_target_list
  , sum(case when is_exclusive_trg then 1 else 0 end) as number_of_exclusive_source
  , listagg(
    case when is_exclusive_trg then column_name end, ', '
  ) within group (order by column_name) as exclusive_source_list

from {{ ref('schema_check') }}

group by all
