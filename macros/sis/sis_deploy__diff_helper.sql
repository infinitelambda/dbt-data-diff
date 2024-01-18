{% macro sis_deploy__diff_helper(package_dir='dbt_packages/data_diff') -%}

  {% set ns = data_diff.get_namespace() %}

  {% set query %}

    create schema if not exists {{ ns }};
    create or replace stage {{ ns }}.stage_diff_helper
      directory = ( enable = true )
      comment = 'Named stage for diff helper SiS appilication';

    PUT file://{{ package_dir }}/macros/sis/diff_helper.py @{{ ns }}.stage_diff_helper overwrite=true auto_compress=false;

    create or replace streamlit {{ ns }}.data_diff_helper
      root_location = '@{{ ns }}.stage_diff_helper'
      main_file = '/diff_helper.py'
      query_warehouse = {{ target.warehouse or 'compute_wh' }}
      comment = 'Streamlit app for the dbt-data-diff package';
  {% endset %}

  {{ log("[RUN]: sis_deploy__diff_helper", info=True) if execute }}
  {{ log("query: " ~ query, info=True) if execute }}
  {% set results = run_query(query) %}
  {{ log(results.rows, info=True) }}

{%- endmacro %}
