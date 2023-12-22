{% macro create__check_schema() %}

    {% set configured_table_model -%} {{ ref("configured_tables").identifier }} {%- endset %}
    {% set log_model -%} {{ ref("log_for_validation").identifier }} {%- endset %}
    {% set result_model -%} {{ ref("schema_check").identifier }} {%- endset %}

    {% set namespace -%}
        {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
    {%- endset %}

    {% set query -%}

    create or replace procedure {{ namespace }}.check_schema(p_batch varchar)
    returns varchar
    language sql
    as
    $$
        declare

            sql_statement varchar;
            run_timestamp timestamp;

            c1 cursor for

                select  '
                        insert into {{ result_model }} (
                            src_db,
                            src_schema,
                            src_table,
                            trg_db,
                            trg_schema,
                            trg_table,
                            column_name,
                            data_type,
                            datetime_precision,
                            numeric_precision,
                            numeric_scale,
                            common_col,
                            common_col_text,
                            is_exclusive_src,
                            is_exclusive_trg,
                            datatype_check,
                            last_data_diff_timestamp
                        )

                        with tables_to_compare as (

                            select  *
                            from    {{ configured_table_model }}
                            where   true
                                and is_enabled = true
                                and src_db      ilike ''' || b.src_db || '''
                                and src_schema  ilike ''' || b.src_schema || '''
                                and src_table   ilike ''' || b.src_table || '''
                                and trg_db      ilike ''' || b.trg_db || '''
                                and trg_schema  ilike ''' || b.trg_schema || '''
                                and trg_table   ilike ''' || b.trg_table || '''

                        ),

                        src_meta as (

                            select  t.*
                                    ,table_schema
                                    ,table_name
                                    ,column_name
                                    ,data_type
                                    ,datetime_precision
                                    ,numeric_precision
                                    ,numeric_scale

                            from    '|| src_db ||'.information_schema.columns c
                            join    tables_to_compare t
                                on  t.src_schema ilike c.table_schema
                                and t.src_table ilike c.table_name

                        ),

                        trg_meta as (

                            select  t.*
                                    ,table_schema
                                    ,table_name
                                    ,column_name
                                    ,data_type
                                    ,datetime_precision
                                    ,numeric_precision
                                    ,numeric_scale

                            from    '|| trg_db ||'.information_schema.columns c
                            join    tables_to_compare t
                                on  t.trg_schema ilike c.table_schema
                                and t.trg_table ilike c.table_name

                        ),

                        common_meta as (

                            select      coalesce(src.src_db, trg.src_db) as src_db
                                        ,coalesce(src.src_schema, trg.src_schema) as src_schema
                                        ,coalesce(src.src_table, trg.src_table) as src_table
                                        ,coalesce(src.trg_db, trg.trg_db) as trg_db
                                        ,coalesce(src.trg_schema, trg.trg_schema) as trg_schema
                                        ,coalesce(src.trg_table, trg.trg_table) as trg_table
                                        ,coalesce(src.column_name, trg.column_name) as column_name
                                        ,coalesce(src.data_type, trg.data_type) as data_type
                                        ,coalesce(src.datetime_precision, trg.datetime_precision) as datetime_precision
                                        ,coalesce(src.numeric_precision, trg.numeric_precision) as numeric_precision
                                        ,coalesce(src.numeric_scale, trg.numeric_scale) as numeric_scale
                                        ,case when src.column_name = trg.column_name then 1 else 0 end as common_col
                                        ,case
                                            when src.column_name = trg.column_name then ''common''
                                            when trg.column_name is not null then ''target only''
                                            when src.column_name is not null then ''source only''
                                        end as common_col_text
                                        ,case when trg.column_name is null then 1 else 0 end as is_exclusive_src
                                        ,case when src.column_name is null then 1 else 0 end as is_exclusive_trg
                                        ,case
                                            when concat(
                                                    ifnull(nullif(upper(trim(cast(src.data_type as varchar))), ''''), ''^^''),
                                                    ifnull(nullif(upper(trim(cast(src.datetime_precision as varchar))), ''''), ''^^''),
                                                    ifnull(nullif(upper(trim(cast(src.numeric_precision as varchar))), ''''), ''^^''),
                                                    ifnull(nullif(upper(trim(cast(src.numeric_scale as varchar))), ''''), ''^^'')
                                                    ) = concat(
                                                        ifnull(nullif(upper(trim(cast(trg.data_type as varchar))), ''''), ''^^''),
                                                        ifnull(nullif(upper(trim(cast(trg.datetime_precision as varchar))), ''''), ''^^''),
                                                        ifnull(nullif(upper(trim(cast(trg.numeric_precision as varchar))), ''''), ''^^''),
                                                        ifnull(nullif(upper(trim(cast(trg.numeric_scale as varchar))), ''''), ''^^'')
                                                    )
                                                then 1
                                            else 0
                                        end as datatype_check
                                        ,''' || ? || ''' last_data_diff_timestamp

                            from        src_meta as src
                            full join   trg_meta as trg
                                on      trg.src_db = src.src_db
                                and     trg.src_schema = src.src_schema
                                and     trg.src_table = src.src_table
                                and     trg.trg_db = src.trg_db
                                and     trg.trg_schema = src.trg_schema
                                and     trg.trg_schema = src.trg_schema
                                and     trg.column_name = src.column_name

                        )

                        select  *
                        from    common_meta ' as sql

                from    {{ configured_table_model }} as b
                where   true
                    and is_enabled = true
                    and coalesce(batch, '') = ?
                order by src_table;

        begin

            run_timestamp := sysdate();

            open c1 using(:run_timestamp, :p_batch);

                for record in c1 do

                sql_statement := record.sql;

                insert into {{ log_model }} (start_time, end_time, sql_statement,diff_type )
                values (:run_timestamp, null, :sql_statement, 'schema');

                execute immediate :sql_statement;

                update  {{ log_model }}
                set     end_time =  sysdate()
                where   start_time = :run_timestamp
                    and sql_statement = :sql_statement;

                end for;

            close c1;

        end;
    $$
    ;

  {% endset %}

  {{ return(query) }}

{%- endmacro %}
