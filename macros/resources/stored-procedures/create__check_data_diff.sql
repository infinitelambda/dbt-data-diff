{% macro create__check_data_diff() -%}

    {% set configured_table_model -%} {{ ref("configured_tables").identifier }} {%- endset %}
    {% set log_model -%} {{ ref("log_for_validation").identifier }} {%- endset %}
    {% set result_schema_model -%} {{ ref("schema_check").identifier }} {%- endset %}
    {% set result_model -%} {{ ref("data_diff_check").identifier }} {%- endset %}

    {% set namespace -%}
        {{ generate_database_name(var("data_diff__database", target.database)) }}.{{ generate_schema_name(var("data_diff__schema", target.schema)) }}
    {%- endset %}

    {% set query -%}

    create or replace procedure {{ namespace }}.check_data_diff()
    returns varchar
      language sql
      as
      $$
        declare
            sql_statement varchar;
            run_timestamp timestamp;

            c1 cursor for

                with {{ configured_table_model }}_tmp as (

                    select  *
                    from    {{ configured_table_model }}
                    where   true
                    and   is_enabled = true

                ),

                pk_base as (

                    select  {{ configured_table_model }}_tmp.*
                            ,table1.value
                            ,'ifnull(nullif(upper(trim(cast(trg.'|| table1.value ||' as varchar))), ''''), ''^^'')'  as trg_pk_null
                            ,'ifnull(nullif(upper(trim(cast(src.'|| table1.value ||' as varchar))), ''''), ''^^'')'  as src_pk_null
                            ,'upper(trim(cast('|| table1.value ||' as varchar)))'  as combined_pk
                            ,'upper(trim(cast(trg.'|| table1.value ||' as varchar)))'  as trg_pk
                            ,'upper(trim(cast(src.'|| table1.value ||' as varchar)))'  as src_pk

                    from    {{ configured_table_model }}_tmp, table(split_to_table(pk, ',')) as table1

                ),

                {{ configured_table_model }}_final as (

                select  src_db
                        ,src_schema
                        ,src_table
                        ,trg_db
                        ,trg_schema
                        ,trg_table
                        ,pk
                        ,include_columns
                        ,exclude_columns
                        ,listagg(combined_pk ,'||') as combined_unique_key
                        ,listagg(src_pk ,'||') as src_unique_key
                        ,listagg(trg_pk ,'||') as trg_unique_key
                from    pk_base
                group by all

                ),

                schema_validation as (

                    select  *
                    from    {{ result_schema_model }}
                    where   true
                    and   common_col = 1 -- only available mutual columns
                    qualify row_number() over(
                        partition by src_db, src_schema, src_table, trg_db, trg_schema, trg_table, column_name
                        order by last_data_diff_timestamp desc
                    ) = 1

                ),

                base as (

                    select  t.*
                            ,listagg(column_name, ',') as col_list
                            ,'cast(md5_binary(concat_ws(''||'','
                                || listagg('ifnull(nullif(upper(trim(cast(' || column_name || ' as varchar))), ''''), ''^^'')', ',' )
                                || ' )) as binary(16)) as hashdiff' as hash_calc
                            ,listagg('ifnull(nullif(upper(trim(cast(src.'|| column_name ||' as varchar))),''''),''^^'')= ifnull(nullif(upper(trim(cast(trg.'|| column_name ||' as varchar))),''''),''^^'') as '|| column_name || '_is_equal', ',' ) as is_equal
                            ,listagg('sum(case when '|| column_name ||'_is_equal then 1 else 0 end) as '|| column_name || '_diff', ',' )  as diff_calc
                            ,listagg(column_name ||'_diff / cnt as '|| column_name, ',')  as result_calc

                    from    {{ configured_table_model }}_final  t
                    join    schema_validation  v
                    on    t.src_schema = v.src_schema
                    and   t.src_table = v.src_table
                    where   true
                    --excluded columns i.e always changing column, added or removed column
                    and   (not array_contains(column_name::variant, t.exclude_columns))
                    and   (
                                case
                                    when array_size(include_columns) > 0
                                        then array_contains(column_name::variant, t.include_columns)
                                    else true
                                end
                            )
                    group by all

                )

                select  '
                        create or replace table {{ result_model }}_' || src_table ||  '_' || to_char(sysdate(),'yyyymmdd') || '
                        as
                        with different_in_source as (
                            (select ' || concat(col_list, ',' , combined_unique_key || ' as combined_unique_key') || ' from '|| src_db || '.' || src_schema || '.' || src_table  || ')
                            except
                            (select ' || concat(col_list, ',' , combined_unique_key || ' as combined_unique_key') || ' from '|| trg_db || '.' || trg_schema || '.' || trg_table  || ')
                        ),
                        different_in_target as (
                            (select ' || concat(col_list, ',' , combined_unique_key || ' as combined_unique_key') || ' from '|| trg_db || '.' || trg_schema || '.' || trg_table  || ')
                            except
                            (select ' || concat(col_list, ',' , combined_unique_key || ' as combined_unique_key') || ' from '|| src_db || '.' || src_schema || '.' || src_table  || ')
                        ),
                        compare_content as (

                            select ''different_in_source'' as type_of_diff, * from different_in_source
                            union
                            select ''different_in_target'' as type_of_diff, * from different_in_target
                        )
                        select  *
                                , ''' || ? || ''' as last_data_diff_timestamp
                        from    compare_content' as sql_data_diff__for_a_table,

                        '
                        insert into {{ result_model }} (
                            src_db,
                            src_schema,
                            src_table,
                            trg_db,
                            trg_schema,
                            trg_table,
                            column_name,
                            match_percentage,
                            last_data_diff_timestamp
                        )
                        with compare_content as (

                            select * from {{ result_model }}_' || src_table ||  '_' || to_char(sysdate(),'yyyymmdd') || '

                        ),
                        column_compare as (
                            select  cc.combined_unique_key, ' || is_equal ||'
                            from    compare_content as cc
                            join    '|| src_db || '.' || src_schema || '.'|| src_table  || ' as src
                                on  '|| src_unique_key || ' = cc.combined_unique_key
                            join    '|| trg_db || '.' || trg_schema || '.'|| trg_table  || ' as trg
                                on  '|| trg_unique_key || ' = cc.combined_unique_key
                        ),
                        final as (
                            select  '''|| src_db || ''' as src_db
                                    ,'''|| src_schema || ''' as src_schema
                                    ,'''|| src_table  || ''' as src_table
                                    ,'''|| trg_db || ''' as trg_db
                                    ,'''|| trg_schema || ''' as trg_schema
                                    ,'''|| trg_table  || ''' as trg_table
                                    ,count(*) as cnt
                                    ,'|| diff_calc  ||
                                    ', '|| result_calc || '
                            from    column_compare
                        )
                        select  src_db
                                ,src_schema
                                ,src_table
                                ,trg_db
                                ,trg_schema
                                ,trg_table
                                ,column_name
                                ,match_percentage
                                ,''' || ? ||'''as last_data_diff_timestamp
                        from    final
                        unpivot (
                            match_percentage
                            for column_name in (' || col_list || ')
                        )
                        where   match_percentage < 1' as sql_data_diff__pivot_summary

                from    base
                order by src_table;

    begin
        run_timestamp := sysdate();

        open c1 using(:run_timestamp, :run_timestamp);

          for record in c1 do
            sql_statement := record.sql_data_diff__for_a_table;

            insert into {{ log_model }} (start_time, end_time, sql_statement, diff_type)
            values (:run_timestamp, null, :sql_statement, 'data-diff');

            execute immediate :sql_statement;

            update  {{ log_model }}
            set     end_time =  sysdate()
            where   start_time = :run_timestamp
              and   sql_statement = :sql_statement;


            sql_statement := record.sql_data_diff__pivot_summary;

            insert into {{ log_model }} (start_time, end_time, sql_statement,diff_type )
            values (:run_timestamp, null, :sql_statement, 'data-diff');

            execute immediate :sql_statement;

            update  {{ log_model }}
            set     end_time =  sysdate()
            where   start_time = :run_timestamp
              and   sql_statement = :sql_statement;

          end for;

        close c1;

    end;
    $$
    ;

  {% endset %}

  {{ return(query) }}

{%- endmacro %}
