
-- Use the `ref` function to select from other models

select id, id_description
from {{ ref('my_first_dbt_model') }}
where true
{# and id is not null  #}
and coalesce(id, 1) = 1
