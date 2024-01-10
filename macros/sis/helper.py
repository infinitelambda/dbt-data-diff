import streamlit as st
from snowflake.snowpark.context import get_active_session

# Header
st.title("Data Diff Helpers")
st.write("""
Aggregation of the diff result produced by the package [dbt-data-diff](https://gitlab.infinitelambda.com/infinitelambda/bi-chapter/dbt-data-diff)
""")

# Get the current credentials
session = get_active_session()

# Implementation
st.subheader("1. Key diff:")
sql = f"select * from {{ ref('key_check_summary)' }}"
data = session.sql(sql).collect()
st.dataframe(data, use_container_width=True)

st.subheader("2. Schema diff:")
sql = f"select * from {{ ref('schema_check_summary)' }}"
data = session.sql(sql).collect()
st.dataframe(data, use_container_width=True)

st.subheader("3. Data diff:")
sql = f"select * from {{ ref('data_diff_check)' }}"
data = session.sql(sql).collect()
st.dataframe(data, use_container_width=True)
