<!-- markdownlint-disable no-inline-html no-alt-text ul-indent code-block-style -->
# dbt-data-diff

<img align="right" width="150" height="150" src="./assets/img/il-logo.png">

[![dbt-hub](https://img.shields.io/badge/Visit-dbt--hub%20↗️-FF694B?logo=dbt&logoColor=FF694B)](https://hub.getdbt.com/infinitelambda/dbt-data-diff)

Data-diff solution for dbt-ers with Snowflake ❄️ 🌟

**_Who is this for?_**

- Primarily for people who want to perform Data-diff validation on **[the Blue-Green deployment](https://discourse.getdbt.com/t/performing-a-blue-green-deploy-of-your-dbt-project-on-snowflake/1349)** 🚀
- Other good considerations 👍
    - UAT validation: data-diff with PROD
    - Code-Refactoring validation: data diff between old vs new
    - Migration to Snowflake: data diff between old vs new (requires to land the old data to Snowflake)
    - CI: future consideration only ⚠️

## Core Concept 🌟

`dbt-data-diff` package provides the diff results into 3 categories or 3 levels of the diff as follows:

- 🥉 **Key diff** ([models](https://github.com/infinitelambda/dbt-data-diff/tree/main/models/01_key_diff/)): Compare the Primary Key (`pk`) only
- 🥈 **Schema diff** ([models](https://github.com/infinitelambda/dbt-data-diff/tree/main/models/02_schema_diff/)): Compare the list of column's Names and Data Types
- 🥇 **Content diff** (aka Data diff) ([models](https://github.com/infinitelambda/dbt-data-diff/tree/main/models/03_content_diff/)): Compare all cell values. The columns will be filtered by each table's configuration (`include_columns` and `exclude_columns`), and the data can be also filtered by the `where` config. Behind the scenes, this operation does not require the Primary Key (PK) config, it will perform Bulk Operation (`INTERCEPT` or `MINUS`) and make an aggregation to make up the column level's match percentage

Sample diffing:
<img src="./assets/img/data-diff.jpeg" alt="Sample diffing">

Behind the scenes, this package leverages the ❄️ [Scripting Stored Procedure](https://docs.snowflake.com/en/developer-guide/stored-procedure/stored-procedures-snowflake-scripting) which provides the 3 ones correspondingly with 3 categories as above. Moreover, it utilizes the [DAG of Tasks](https://docs.snowflake.com/en/user-guide/tasks-intro?utm_source=legacy&utm_medium=serp&utm_term=task+DAG#label-task-dag) to optimize the speed with the parallelism once enabled by configuration 🚀

Sample DAG:

<img src="./assets/img/Sample_DAG_of_Tasks.png" alt="Sample DAG">

## Installation

- Add to `packages.yml` file:

```yml
packages:
  - package: infinitelambda/dbt-data-diff
    version: [">=1.0.0", "<1.1.0"]
```

Or use the latest version from git:

```yml
packages:
  - git: "https://github.com/dbt-labs/dbt-utils.git"
    revision: 1.0.0 # 1.0.0b1
```

- (Optional) Configure database & schema in `dbt_project.yml` file:

```yml
vars:
  # (optional) default to `target.database` if not specified
  data_diff__database: COMMON
  # (optional) default to `target.schema` if not specified
  data_diff__schema: DATA_DIFF
```

- Create/Migrate the `data-diff`'s DDL resources

```bash
dbt deps
dbt run -s data_diff --vars '{data_diff__on_migration: true}'
```

## Quick Start

### 1. Configure the tables that need comparing in `dbt_project.yml`

We're going to use the `data_diff__configured_tables` variable (Check out the [dbt_project.yml](https://github.com/infinitelambda/dbt-data-diff/tree/main/dbt_project.yml)/`vars` section for more details!)

For example, we want to compare `table_x` between **PROD** db and **DEV** one:

```yaml
vars:
  data_diff__configured_tables:
    - src_db: your_prod
      src_schema: your_schema
      src_table: table_x
      trg_db: your_dev
      trg_schema: your_schema
      trg_table: table_x
      pk: key # multiple columns splitted by comma
      include_columns: [] # [] to include all
      exclude_columns: ["loaded_at"] # [] to exclude loaded_at field
```

### 2. Refresh the configured tables's data

We can skip this step if you already did it. If not, let's run the below command:

```bash
dbt run -s data_diff \
  --full-refresh \
  --vars '{data_diff__on_migration: true, data_diff__on_migration_data: true, data_diff__full_refresh: true}'
```

!!! note "In the above:"

    - `--full-refresh` and `data_diff__full_refresh`: To re-create all data-diff models
    - `data_diff__on_migration: true`: To re-create the stored procedures
    - `data_diff__on_migration_data: true`: To reset the configured data

### 3. Trigger the validation via dbt operation

Now, let's start the diff run:

```bash
dbt run-operation data_diff__run        # normal mode, run in sequence, wait unitl finished
# OR
dbt run-operation data_diff__run_async  # async mode, parallel, no waiting
dbt run-operation data_diff__run_async --args '{is_polling_status: true}'
                                        # async mode, parallel, status polling
```

!!! tip "In the Async Mode"
    We leverage the DAG of tasks, therefore the dbt's ROLE will need granting the addtional privilege:

    ```sql
    use role accountadmin;
    grant execute task on account to role {{ target.role }};
    ```

<details>
  <summary>📖 Or via dbt hook by default (it will run an incremental load for all models)</summary>

```yaml
# Add into dbt_project.yml file

# normal mode
on-run-end
  - > # run data-diff hook
    {% if var("data_diff__on_run_hook", false) %}
      {{ data_diff.data_diff__run(in_hook=true) }}
    {% endif %}

# async mode
on-run-end
  - > # run data-diff hook
    {% if var("data_diff__on_run_hook", false) %}
      {{ data_diff.data_diff__run_async(in_hook=true) }}
    {% endif %}

```

```bash
# terminal
dbt run -s data_diff --vars '{data_diff__on_run_hook: true}'
```

</details>

### 4. [Bonus] Deploy the helper 🤩

Our helper is the [Streamlit in Snowflake](https://www.snowflake.com/en/data-cloud/overview/streamlit-in-snowflake/) (SiS) application which was built on the last diff result in order to help us to have a better examining with the actual result without typing SQL.

Let's deploy the Streamlit app by running the dbt command as follows:

```bash
dbt run-operation sis_deploy__diff_helper
```

<details>
  <summary>Sample logs</summary>

```log
02:44:50  Running with dbt=1.7.4
02:44:52  Registered adapter: snowflake=1.7.1
02:44:53  Found 16 models, 2 operations, 21 tests, 0 sources, 0 exposures, 0 metrics, 558 macros, 0 groups, 0 semantic models
02:44:53  [RUN]: sis_deploy__diff_helper
02:44:53  query:

    create schema if not exists data_diff.blue_dat_common;
    create or replace stage data_diff.blue_dat_common.stage_diff_helper
      directory = ( enable = true )
      comment = 'Named stage for diff helper SiS appilication';

    PUT file://dbt_packages/data_diff/macros/sis/diff_helper.py @data_diff.blue_dat_common.stage_diff_helper overwrite=true auto_compress=false;

    create or replace streamlit data_diff.blue_dat_common.data_diff_helper
      root_location = '@data_diff.blue_dat_common.stage_diff_helper'
      main_file = '/diff_helper.py'
      query_warehouse = wh_data_diff
      comment = 'Streamlit app for the dbt-data-diff package';

02:45:02  <agate.MappedSequence: (<agate.Row: ('Streamlit DATA_DIFF_HELPER successfully created.')>)>
```

</details>

Once it's done, you could access to the app via: **Steamlit menu** / **DATA_DIFF_HELPER** or via this quick link:

```log
{BASE_SNOWFLAKE_URL}/#/streamlit-apps/{DATABASE}.{SCHEMA}.DATA_DIFF_HELPER
```

<details>
  <summary>👉 Check out the sample app UI</summary>

<img src="./assets/img/sis_ui.png" alt="Sample SiS">

</details>

## Demo

**Part 1**: Configure and prepare Blue/Green

[![Watch the video - P1](https://cdn.loom.com/sessions/thumbnails/2445f322720a4466ab9494c90e66946b-1705309091927-with-play.gif)](https://www.loom.com/share/2445f322720a4466ab9494c90e66946b?sid=9b5f354c-3611-412a-ac18-554e4b879913)

**Part 2**: Run data diff & examine the result

[![Watch the video - P2](https://cdn.loom.com/sessions/thumbnails/c4dc4179a4ee4a0d9583db405b46e969-1705308496485-with-play.gif)](https://www.loom.com/share/c4dc4179a4ee4a0d9583db405b46e969?sid=fc6e2dd8-c456-4888-8eaf-64883423270d)

## Variables

!!! tip "See `dbt_project.yml` file"
    Go to `vars` section [here](https://github.com/infinitelambda/dbt-data-diff/blob/main/dbt_project.yml#L12) 🏃

    We managed to provide the inline comments only for now, soon to have the dedicated page for more detail explanation.

Here are the full list of built-in variables:

- `data_diff__database`
- `data_diff__schema`
- `data_diff__on_migration`
- `data_diff__on_migration_data`
- `data_diff__on_run_hook`
- `data_diff__full_refresh`
- `data_diff__configured_tables__source_fixed_naming`
- `data_diff__configured_tables__target_fixed_naming`
- `data_diff__configured_tables`
- `data_diff__auto_pipe`

## How to Contribute ❤️

`dbt-data-diff` is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

👉 See [CONTRIBUTING guideline](https://data-diff.iflambda.com/latest/nav/dev/contributing.html) for more details or check out [CONTRIBUTING.md](https://github.com/infinitelambda/dbt-data-diff/tree/main/CONTRIBUTING.md)

🌟 And then, kudos to **our beloved Contributors**:

<a href="https://github.com/infinitelambda/dbt-data-diff/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=infinitelambda/dbt-data-diff" alt="Contributors" />
</a>

⭐ Special Credits to [👱 Attila Berecz](https://www.linkedin.com/in/attila-berecz-a0bb5ba2/) who is the OG Contributor of the Core Concept and all the Snowflake Stored Procedures

## Features comparison to the alternative packages

| Feature               | Supported Package                                          | Notes                                 |
|:----------------------|:-----------------------------------------------------------|:-----------------|
| Key diff              | <ul><li>`dbt_data_diff`</li><li>[`data_diff`](https://github.com/datafold/data_diff)</li><li>[`dbt_audit_helper`](https://github.com/dbt-labs/dbt_audit_helper)</li></ul> | ✅ all available |
| Schema diff           | <ul><li>`dbt_data_diff`</li><li>[`data_diff`(*)](https://github.com/datafold/data_diff)</li><li>[`dbt_audit_helper`](https://github.com/dbt-labs/dbt_audit_helper)</li></ul> | (*): Only available in the paid-version 💰 |
| Content diff          | <ul><li>`dbt_data_diff`</li><li>[`data_diff`(*)](https://github.com/datafold/data_diff)</li><li>[`dbt_audit_helper`](https://github.com/dbt-labs/dbt_audit_helper)</li></ul> | (*): Only available in the paid-version 💰 |
| Yaml Configuration    | <ul><li>`dbt_data_diff`</li></ul>                           | `data_diff` will use the `toml` file, `dbt_audit_helper` will require to create new models for each comparison |
| Query & Execution log  | <ul><li>`dbt_data_diff`</li></ul>                           | Except for dbt's log, this package to be very transparent on which diff queries executed which are exposed in [`log_for_validation`](https://github.com/infinitelambda/dbt-data-diff/tree/main/models/log_for_validation.yml) model |
| Snowflake-native Stored Proc | <ul><li>`dbt_data_diff`</li></ul>                      | Purely built as Snowflake SQL native stored procedures |
| Parallelism           | <ul><li>`dbt_data_diff`</li><li>[`data_diff`](https://github.com/datafold/data_diff)</li><li>[`dbt_audit_helper`](https://github.com/dbt-labs/dbt_audit_helper)</li></ul> | `dbt_data_diff` leverages Snowflake Task DAG, the others use python threading |
| Asynchronous          | <ul><li>`dbt_data_diff`</li></ul>                           | Trigger run & go away. Decide to continously poll the run status and waiting until finished if needed |
| Multi-warehouse supported | <ul><li>`dbt_data_diff`(*)</li><li>[`data_diff`](https://github.com/datafold/data_diff)</li><li>[`dbt_audit_helper`](https://github.com/dbt-labs/dbt_audit_helper)</li></ul> | (*): Future Consideration 🏃 |

## About Infinite Lambda

Infinite Lambda is a cloud and data consultancy. We build strategies, help organizations implement them, and pass on the expertise to look after the infrastructure.

We are an Elite Snowflake Partner, a Platinum dbt Partner, and a two-time Fivetran Innovation Partner of the Year for EMEA.

Naturally, we love exploring innovative solutions and sharing knowledge, so go ahead and:

🔧 Take a look around our [Git](https://github.com/infinitelambda)

✏️ Browse our [tech blog](https://infinitelambda.com/category/tech-blog/)

We are also chatty, so:

👀 Follow us on [LinkedIn](https://www.linkedin.com/company/infinite-lambda/)

👋🏼 Or just [get in touch](https://infinitelambda.com/contacts/)

[<img src="https://raw.githubusercontent.com/infinitelambda/cdn/1.0.0/general/images/GitHub-About-Section-1080x1080.png" alt="About IL" width="500">](https://infinitelambda.com/)
