import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(layout="wide")

# Header
st.title("Data Diff Helpers")
st.write("""
Aggregation of the diff result produced by the package [dbt-data-diff](https://gitlab.infinitelambda.com/infinitelambda/bi-chapter/dbt-data-diff)
""")

# Get the current credentials
session = get_active_session()

# Summary
st.subheader("🥉 Key diff:")
sql = """
    with

    last_key_check_summary as (
        select  *
        from    key_check_summary
        qualify row_number() over (
            partition by src_db,src_schema,src_table,trg_db,trg_schema,trg_table
            order by last_data_diff_timestamp desc
        ) = 1
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
sql = """
    with

    last_schema_check_summary as (
        select  *
        from    schema_check_summary
        qualify row_number() over (
            partition by src_db,src_schema,src_table,trg_db,trg_schema,trg_table
            order by last_data_diff_timestamp desc
        ) = 1
    )

    select      case when r.src_db is null then '🟢' else '🔴' end as result
                ,concat(r.number_of_exclusive_source, ' (',upper(r.exclusive_source_list),')') as source_not_found
                ,concat(r.number_of_exclusive_source, ' (',upper(r.exclusive_target_list),')') as target_not_found
                ,coalesce(1 - r.mutual_columns * 1.0 / r.number_of_columns, 0) as failed_rate
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
sql = """
    with

    last_data_diff_check as (
        select  *
        from    data_diff_check
        qualify row_number() over (
            partition by src_db,src_schema,src_table,trg_db,trg_schema,trg_table,column_name
            order by last_data_diff_timestamp desc
        ) = 1
    )

    select      case when r.src_db is null then '🟢' else '🔴' end as result
                ,r.column_name
                ,concat(100 - r.match_percentage * 100, ' %') as diff_feeded_rate
                ,concat(
                    c.src_db,'.',c.src_schema,'.',c.src_table,
                    ' ▶️ ',
                    c.trg_db,'.',c.trg_schema,'.',c.trg_table
                ) as entity

    from        configured_tables as c
    left join   last_data_diff_check as r
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
if st.button("Sampling Failures ▶️"):
    sql = """
        with

        last_data_diff_check as (
            select  *
            from    data_diff_check
            qualify row_number() over (
                partition by src_db,src_schema,src_table,trg_db,trg_schema,trg_table,column_name
                order by last_data_diff_timestamp desc
            ) = 1
        )

        select  concat(
                    src_db,'.',src_schema,'.',src_table,
                    ' ▶️ ',
                    trg_db,'.',trg_schema,'.',trg_table
                ) as entity
                ,column_name
                ,'with

                src as (
                    select  *
                    from    data_diff_check_' || src_table || '_' || to_varchar(last_data_diff_timestamp, 'YYYYMMDD') || '
                    where   type_of_diff = ''different_in_source''
                ),

                trg as (
                    select  *
                    from    data_diff_check_' || src_table || '_' || to_varchar(last_data_diff_timestamp, 'YYYYMMDD') || '
                    where   type_of_diff = ''different_in_target''
                )

                select  src.' || column_name || ' as ' || column_name || '__source
                        ,trg.' || column_name || ' as ' || column_name || '__target
                        , src.combined_unique_key

                from    src
                join    trg using (combined_unique_key)

                where   hash(src.' || column_name || ') != hash(trg.' || column_name || ')

                limit   10;
                ' as drilldown_script

        from    last_data_diff_check
        order by match_percentage
    """
    data = session.sql(sql).collect()
    for item in data:
        item_dict = item.as_dict()
        with st.expander(f"🟡 **{item_dict.get('COLUMN_NAME')}** / {item_dict.get('ENTITY')}", expanded=False):
            st.markdown(f"_(only 10 rows maximum)_")
            sql = item_dict.get("DRILLDOWN_SCRIPT")
            sql_data = session.sql(sql).collect()
            st.dataframe(sql_data, use_container_width=True)
            st.markdown("Used query:")
            st.code(sql.replace("                ","  "), language='sql')
