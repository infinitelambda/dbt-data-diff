{% set expected_namespace -%}
  {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
{%- endset -%}

select '' as test_case, '{{ data_diff.get_namespace() }}' as actual, '{{ expected_namespace }}' as expected
