-- Use the `ref` function to select from other models

select *
from data_diff.DOCS.my_first_dbt_model
where true

and coalesce(id, 1) = 1