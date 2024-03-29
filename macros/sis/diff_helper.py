import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(layout="wide")

# Header
st.title("Data Diff Helpers")
st.write("""
Aggregation of the diff result produced by the package [dbt-data-diff](https://data-diff.iflambda.com/latest/)
""")

# Get the current credentials
session = get_active_session()

# Query the last Diff Run ID
sql = "select diff_run_id from log_for_validation order by diff_start_time desc limit 1"
data = session.sql(sql).collect()
last_run_id = data[0].as_dict().get('DIFF_RUN_ID') if len(data) > 0 else None
st.caption(f"Last Run ID: {last_run_id}")

if not last_run_id:
    st.warning("No diff result found!")
else:
    # Summary
    st.subheader("🥉 Key diff:")
    st.caption("Compare the Primary Key (`pk`) only")
    sql = f"""
        with

        last_key_check_summary as (
            select  *
            from    key_check_summary
            where   diff_run_id = '{last_run_id}'
        )

        select      case when r.src_db is null then '🟢' else '🔴' end as result
                    ,concat(r.number_of_exclusive_src, ' (',upper(r.pk),')') as source_not_found
                    ,concat(r.number_of_exclusive_trg, ' (',upper(r.pk),')') as target_not_found
                    ,concat(
                        c.src_db,'.',c.src_schema,'.',c.src_table,
                        ' ▶️ ',
                        c.trg_db,'.',c.trg_schema,'.',c.trg_table
                    ) as entity

        from        configured_tables as c
        left join   last_key_check_summary as r
            on      r.src_db = c.src_db
            and     r.src_schema = c.src_schema
            and     r.src_table = c.src_table
            and     r.trg_db = c.trg_db
            and     r.trg_schema = c.trg_schema
            and     r.trg_table = c.trg_table

        where       r.src_db is not null
            or      c.is_enabled = true
    """
    data = session.sql(sql).collect()
    st.dataframe(data, use_container_width=True)

    st.subheader("🥈 Schema diff:")
    st.caption("Compare the data structure (column's Names and Data Types)")
    sql = f"""
        with

        last_schema_check_summary as (
            select  *
            from    schema_check_summary
            where   diff_run_id = '{last_run_id}'
        )

        select      case when r.src_db is null then '🟢' else '🔴' end as result
                    ,case
                        when r.number_of_exclusive_source > 0 then concat(r.number_of_exclusive_source, ' (',upper(r.exclusive_source_list),')')
                    end as source_not_found
                    ,case
                        when r.number_of_exclusive_source > 0 then concat(r.number_of_exclusive_source, ' (',upper(r.exclusive_target_list),')')
                    end as target_not_found
                    ,coalesce(1 - r.mutual_columns * 1.0 / r.number_of_columns, 0) as not_found_rate
                    ,case
                        when r.number_of_false_datatype_check > 0 then concat(r.number_of_false_datatype_check, ' (',upper(r.false_datatype_check_list),')')
                    end as data_type_mismatched
                    ,coalesce(r.number_of_false_datatype_check  * 1.0 / r.number_of_columns, 0) as mismatched_rate
                    ,concat(
                        c.src_db,'.',c.src_schema,'.',c.src_table,
                        ' ▶️ ',
                        c.trg_db,'.',c.trg_schema,'.',c.trg_table
                    ) as entity

        from        configured_tables as c
        left join   last_schema_check_summary as r
            on      r.src_db = c.src_db
            and     r.src_schema = c.src_schema
            and     r.src_table = c.src_table
            and     r.trg_db = c.trg_db
            and     r.trg_schema = c.trg_schema
            and     r.trg_table = c.trg_table

        where       r.src_db is not null
            or      c.is_enabled = true
    """
    data = session.sql(sql).collect()
    st.dataframe(data, use_container_width=True)

    st.subheader("🥇 Data diff:")
    st.caption("Compare all cell values given matched columns and mached keys")
    sql = f"""
        with

        last_data_diff_check_summary as (
            select  *
            from    data_diff_check_summary
            where   diff_run_id = '{last_run_id}'
        )

        select      case when r.src_db is null then '🟢' else '🔴' end as result
                    ,r.column_name
                    ,concat(r.match_percentage * 100, ' %') as match_percentage
                    ,concat(r.diff_feeded_rate * 100, ' %') as diff_feeded_rate
                    ,concat(r.diff_count, '/', r.table_count) as diff_count_vs_total
                    ,concat(
                        c.src_db,'.',c.src_schema,'.',c.src_table,
                        ' ▶️ ',
                        c.trg_db,'.',c.trg_schema,'.',c.trg_table
                    ) as entity

        from        configured_tables as c
        left join   last_data_diff_check_summary as r
            on      r.src_db = c.src_db
            and     r.src_schema = c.src_schema
            and     r.src_table = c.src_table
            and     r.trg_db = c.trg_db
            and     r.trg_schema = c.trg_schema
            and     r.trg_table = c.trg_table

        where       r.src_db is not null
            or      c.is_enabled = true

        order by    3 desc
    """
    data = session.sql(sql).collect()
    st.dataframe(data, use_container_width=True)


    # Drill down
    def show_entity_diff_drilldown(session, entity_row, expanded: bool = False):
        entity_dict = entity_row.as_dict()
        with st.expander(f"{entity_dict.get('ENTITY')}", expanded=expanded):
            st.markdown(f"_(only 10 rows maximum)_")
            sql = entity_dict.get("DRILLDOWN_SCRIPT")
            sql_data = session.sql(sql).collect()
            st.dataframe(sql_data, use_container_width=True)
            st.markdown("Used query:")
            st.code(sql.replace("                  ","  "), language='sql')

    sql = f"""
        with

        last_data_diff_check_summary as (
            select  *
            from    data_diff_check_summary
            where   diff_run_id = '{last_run_id}'
        )

        select  concat(
                    '🟡 **', column_name, '** / ',
                    src_db,'.',src_schema,'.',src_table,
                    ' ▶️ ',
                    trg_db,'.',trg_schema,'.',trg_table
                ) as entity
                ,column_name
                ,'with

                src as (
                    select  *
                    from    data_diff_check_summary_' || src_table || '_' || to_varchar(last_data_diff_timestamp, 'YYYYMMDD') || '
                    where   type_of_diff = ''different_in_source''
                ),

                trg as (
                    select  *
                    from    data_diff_check_summary_' || src_table || '_' || to_varchar(last_data_diff_timestamp, 'YYYYMMDD') || '
                    where   type_of_diff = ''different_in_target''
                )

                select  src.' || column_name || ' as _source
                        ,trg.' || column_name || ' as _target
                        , src.combined_unique_key

                from    src
                join    trg using (combined_unique_key)

                where   hash(src.' || column_name || ') != hash(trg.' || column_name || ')

                limit   10;
                ' as drilldown_script

        from    data_diff_check_summary
        where   {{where}}
        order by match_percentage
    """
    entity_options = [
        x.as_dict().get("ENTITY")
        for x in session.sql(f"{sql.format(where='1=1')}").collect()
    ]
    entity_option = st.selectbox(
        label="Let's drill-down by selecting a diff entity to view the sample failure:",
        options=entity_options
    )
    if entity_option:
        entity_drilldown_query = session.sql(sql.format(where=f"entity = '{entity_option}'")).collect()
        show_entity_diff_drilldown(session=session, entity_row=entity_drilldown_query[0], expanded=True)

    if entity_options:
        if st.button("Or see all (Top 10) Failure(s) ▶️"):
            data = session.sql(f"{sql.format(where='1=1')} limit 10").collect()
            for item in data:
                show_entity_diff_drilldown(session=session, entity_row=item)
