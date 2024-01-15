{% set configured_rows = var("data_diff__configured_tables", []) | length %}

select  count(*) as actual, {{ configured_rows }} as expected
from    {{ ref('configured_tables') }}
