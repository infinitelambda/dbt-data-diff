{% set configured_rows = var("data_diff__configured_tables", []) | length %}

select  'key' as diff, count(*) as actual, {{ configured_rows }} as expected
from    {{ ref('log_for_validation') }}
where   diff_type = 'key'

union all

select  'schema' as diff, count(*) as actual, {{ configured_rows }} as expected
from    {{ ref('log_for_validation') }}
where   diff_type = 'schema'

union all

select  'data' as diff, count(*) as actual, {{ configured_rows * 2 }} as expected
from    {{ ref('log_for_validation') }}
where   diff_type = 'data-diff'
