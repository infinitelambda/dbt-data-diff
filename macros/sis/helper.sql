{% macro sis_deploy__helper() -%}

  create or replace schema {{ generate_schema_name("apps") }};
  create or replace streamlit {{ generate_schema_name("apps") }}.data_diff_helper
    root_location = '<stage_path_and_root_directory>'
    main_file = '<path_to_main_file_in_root_directory>'
    comment = 'Streamlit app for the dbt-data-diff package';

{%- endmacro %}
