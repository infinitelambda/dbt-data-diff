{% macro refresh_resource_data() %}

  {% set configured_tables = var("data_diff__configured_tables", []) %}
  {% set source_fixed_naming = var("data_diff__configured_tables__source_fixed_naming", true) %}
  {% set target_fixed_naming = var("data_diff__configured_tables__target_fixed_naming", true) %}
  {% set configured_table_model -%} {{ ref("configured_tables") }} {%- endset %}

  {% set query -%}

    truncate table {{ configured_table_model }};
    insert into {{ configured_table_model }}
    (src_db,src_schema,src_table,trg_db,trg_schema,trg_table,pk,include_columns,exclude_columns,where_condition,is_enabled,pipe_name)

    {% for item in configured_tables -%}

      select

      {% if source_fixed_naming -%}
        '{{ item.get("src_db", target.database) }}' as src_db
        ,'{{ item.get("src_schema", target.schema) }}' as src_schema
      {%- else -%}
        '{{ generate_database_name(item.get("src_db")) }}' as src_db
        ,'{{ generate_schema_name(item.get("src_schema")) }}' as src_schema
      {%- endif -%}
        ,'{{ item.get("src_table") }}' as src_table

      {% if target_fixed_naming -%}
        ,'{{ item.get("trg_db", target.database) }}' as trg_db
        ,'{{ item.get("trg_schema", target.schema) }}' as trg_schema
      {%- else -%}
        ,'{{ generate_database_name(item.get("trg_db")) }}' as trg_db
        ,'{{ generate_schema_name(item.get("trg_schema")) }}' as trg_schema
      {%- endif -%}
        ,'{{ item.get("trg_table", item.get("src_table")) }}' as trg_table

        ,'{{ item.get("pk") }}' as pk
        ,{{ item.get("include_columns", []) | upper }} as include_columns
        ,{{ item.get("exclude_columns", []) | upper }} as exclude_columns
        ,'{{ item.get("where_condition", "1=1") }}' as where_condition
        ,True as is_enabled

      {% if var("data_diff__auto_pipe", false) -%}
        ,coalesce(
          nullif('{{ item.get("pipe_name", "") }}', ''),
          concat(src_db,'_',src_schema,'_',src_table,'__',trg_db,'_',trg_schema,'_',trg_table)
        ) as pipe_name
      {%- else -%}
        ,'{{ item.get("pipe_name", "") }}' as pipe_name
      {%- endif %}

      {% if not loop.last -%}
        union all
      {% endif %}

    {%- endfor %};

  {%- endset %}

  {{ log("[SCRIPT]: refresh_resource_data", info=True) if execute }}
  {{ return(query) }}

{% endmacro %}
