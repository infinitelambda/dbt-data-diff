{% macro create__check_key() %}

    {% set configured_table_model -%} {{ ref("configured_tables").identifier }} {%- endset %}
    {% set log_model -%} {{ ref("log_for_validation").identifier }} {%- endset %}
    {% set result_model -%} {{ ref("key_check").identifier }} {%- endset %}

  {% set namespace = data_diff.get_namespace() %}

    {% set query -%}

    create or replace procedure {{ namespace }}.check_key(p_batch varchar)
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
                    and is_enabled = true
                    and coalesce(pipe_name, '') = ?

            ),

            pk_base as (

                select  {{ configured_table_model }}_tmp.*
                        ,table1.value
                        ,'ifnull(nullif(upper(trim(cast(trg.'|| table1.value ||' as varchar))), ''''), ''^^'')'  as trg_pk_null
                        ,'ifnull(nullif(upper(trim(cast(src.'|| table1.value ||' as varchar))), ''''), ''^^'')'  as src_pk_null
                        ,'upper(trim(cast(trg.'|| table1.value ||' as varchar)))'  as trg_pk
                        ,'upper(trim(cast(src.'|| table1.value ||' as varchar)))'  as src_pk

                from    {{ configured_table_model }}_tmp, table(split_to_table(pk, ',')) as table1

            ),

            final as (

                select  src_db
                        ,src_schema
                        ,src_table
                        ,trg_db
                        ,trg_schema
                        ,trg_table
                        ,pk
                        ,include_columns
                        ,exclude_columns
                        ,where_condition
                        ,listagg(src_pk ,'||')  as src_unique_key
                        ,listagg(trg_pk ,'||')  as trg_unique_key

                from    pk_base
                group by all
            )

            select  '
                    insert into {{ result_model }} (src_db, src_schema, src_table, trg_db, trg_schema, trg_table, pk, key_value, is_exclusive_src, is_exclusive_trg, is_diff_unique_key, last_data_diff_timestamp)
                    with
                    src_data as (
                        select  *
                        from    ' || t.src_db || '.'|| t.src_schema || '.'|| t.src_table  || '
                        where   ' || t.where_condition || '
                    ),
                    trg_data as (
                        select  *
                        from    ' || t.trg_db || '.'|| t.trg_schema || '.'|| t.trg_table  || '
                        where   ' || t.where_condition || '
                    ),
                    insert_part as (
                        select      '''   || t.src_db          || ''' as src_db
                                    , ''' || t.src_schema      || ''' as src_schema
                                    , ''' || t.src_table       || ''' as src_table
                                    , ''' || t.trg_db          || ''' as trg_db
                                    , ''' || t.trg_schema      || ''' as trg_schema
                                    , ''' || t.trg_table       || ''' as trg_table
                                    , ''' || t.pk              || ''' as pk
                                    , '   || src_unique_key    || ' as src_pk
                                    , '   || trg_unique_key    || ' as trg_pk
                                    , coalesce(src_pk, trg_pk) as key_value
                                    , (trg_pk is null) as is_exclusive_src
                                    , (src_pk is null) as is_exclusive_trg
                                    , case when src_pk is distinct from trg_pk then 1 else 0 end as is_diff_unique_key
                                    , ''' || ? || ''' as last_data_diff_timestamp
                        from        src_data as src
                        full join   trg_data as trg
                            on      src_pk = trg_pk
                        where       is_diff_unique_key = 1
                    )
                    select  src_db, src_schema, src_table, trg_db, trg_schema, trg_table, pk, key_value, is_exclusive_src, is_exclusive_trg, is_diff_unique_key, last_data_diff_timestamp
                    from    insert_part
                    ' as sql

            from    final as t
            order by src_table;

    begin

        run_timestamp := sysdate();

        open c1 using(:p_batch, :run_timestamp);

            for record in c1 do

              sql_statement := record.sql;

              insert into {{ log_model }} (start_time, end_time, sql_statement,diff_type)
              values (:run_timestamp, null, :sql_statement, 'key');

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
