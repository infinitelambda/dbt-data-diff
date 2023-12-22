{% macro refresh_configured_tables() %}

  {% set configured_tables = var("data_diff__configured_tables", []) %}
  {% set configured_table_model -%} {{ ref("configured_tables") }} {%- endset %}

  {% set query -%}

    truncate table {{ configured_table_model }};
    insert into {{ configured_table_model }}
    (src_db,src_schema,src_table,trg_db,trg_schema,trg_table,pk,include_columns,exclude_columns,is_enabled)

    {% for item in configured_tables -%}

      select
        '{{ item.get("src_db") }}' as src_db
        ,'{{ item.get("src_schema") }}' as src_schema
        ,'{{ item.get("src_table") }}' as src_table
        ,'{{ item.get("trg_db") }}' as trg_db
        ,'{{ item.get("trg_schema") }}' as trg_schema
        ,'{{ item.get("trg_table") }}' as trg_table
        ,'{{ item.get("pk") }}' as pk
        ,{{ item.get("include_columns", []) | upper }} as include_columns
        ,{{ item.get("exclude_columns", []) | upper }} as exclude_columns
        ,True as is_enabled
      {% if not loop.last -%}
        union all
      {% endif %}

    {%- endfor %};

  {%- endset %}

  {{ log("[SCRIPT]: refresh_configured_tables", info=True) if execute }}
  {{ return(query) }}

{% endmacro %}
