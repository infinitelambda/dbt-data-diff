<!-- markdownlint-disable no-inline-html -->
# dbt-data-diff

Data-diff solution for dbt-ers with Snowflake ❄️ 🚀

**_Who is this for?_**

- Primarily for people who want to perform Data-diff validation on **the Blue-Green deployment** 🌟
- Other good considerations 👍
  - UAT validation: data-diff with PROD
  - Code-Refactoring validation: data diff between old vs new
  - Migration to Snowflake: data diff between old vs new (requires to land the old data to Snowflake)
  - CI: future consideration only ⚠️

## Core Concept 🌟

This package provides the diff results into 3 categories:

- **Key diff**: Compare the Primary Key (`pk`) only.
- **Schema diff**: Compare the List of columns and their Data types.
- **Content diff** (aka Data diff): Compare all column values. The columns will be filtered by each table's configuration (`include_columns` and `exclude_columns`), and the data can be also filtered by the `where` config. Behind the scenes, this operation does not require the Primary Key (PK) config, it will perform Bulk Operation (`INTERCEPT` or `MINUS`) and make an aggregation to make up the column level's match percentage.

Alternative packages for consideration:

| Feature                                         | Supported Package                                               | Notes                           |
|:------------------------------------------------|:----------------------------------------------------------------|:--------------------------------|
| Key diff                                        | `dbt-data-diff` </br>[`data-diff`](https://github.com/datafold/data-diff) </br>[`dbt-audit-helper`](https://github.com/dbt-labs/dbt-audit-helper) | |
| Schema diff                                     | `dbt-data-diff` </br>[`data-diff`*](https://github.com/datafold/data-diff) </br>[`dbt-audit-helper`](https://github.com/dbt-labs/dbt-audit-helper) | (*): Only available in the paid-version 💰 |
| Content diff                                    | `dbt-data-diff` </br>[`data-diff`*](https://github.com/datafold/data-diff) </br>[`dbt-audit-helper`](https://github.com/dbt-labs/dbt-audit-helper) | (*): Only available in the paid-version 💰 |
| Yaml Configuration                              | `dbt-data-diff` | `data-diff` will use the `toml` file, `dbt-audit-helper` will require to create new models for each comparison |
| Query & Execution log                           | `dbt-data-diff` | Except for dbt's log, this package to be very transparent on which diff queries executed which are exposed in `log_for_validation` model |
| Snowflake-native Stored Proc                    | `dbt-data-diff` | Purely built as Snowflake SQL native stored procedures |
| Multi-warehouse supported                       | [`data-diff`](https://github.com/datafold/data-diff) </br>[`dbt-audit-helper`](https://github.com/dbt-labs/dbt-audit-helper) | |

## Installation

- Add to `packages.yml` file:

```yml
packages:
  - package: infinitelambda/dbt-data-diff
    version: [">=1.0.0", "<1.1.0"]
```

- (Optional) Configure database & schema in `dbt_project.yml` file:

```yml
vars:
  # (optional) default to `target.database` if not specified
  data_diff__database: COMMON
  # (optional) default to `target.schema` if not specified
  data_diff__schema: DATA_DIFF
```

- Create/Migrate the `data-diff`'s resources

```bash
dbt deps
dbt run -s data_diff \
  --full-refresh \
  --vars '{data_diff__on_migration: true, data_diff__on_migration_data: true, data_diff__full_refresh: true}'
```

<details> <!-- markdownlint-disable no-inline-html -->
  <summary>💡 click me</summary>

In the above:

- `--full-refresh` and `data_diff__full_refresh`: To re-create all data-diff models
- `data_diff__on_migration: true`: To re-create the stored procedures
- `data_diff__on_migration_data: true`: To reset the configured data

</details>

## Quick Demo

### Configure the tables that need comparing in `dbt_project.yml`

We're going to use the `data_diff__configured_tables` variable (Check out [dbt_project.yml](./dbt_project.yml)/`vars` section for more details!)

For example, we want to compare `table_x` between **prod** db and **dev** one:

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

Then, use the migration command above to reset the configured data.

### Trigger the validation via dbt operation

```bash
dbt run-operation data_diff__run        # normal mode, run in sequence, wait unitl finished
# OR
dbt run-operation data_diff__run_async  # async mode, parallel, no waiting
dbt run-operation data_diff__run_async --args '{is_polling_status: true}'
                                        # async mode, parallel, status polling
```

> **NOTE**: In async mode, we leverage the DAG of tasks, therefore the dbt's ROLE will need granting the addtional privilege:</br></br>
> `use role accountadmin;` </br>
> `grant execute task on account to role {{ target.role }};`</br>

<details> <!-- markdownlint-disable no-inline-html -->
  <summary>Or via dbt hook by default (it will run an incremental load for all models)</summary>

```yaml
# dbt_project.yml

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

<!-- [![Watch the video](TODO.gif)](TODO) -->

## How to Contribute

`dbt-data-diff` is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

👉 See [CONTRIBUTING guideline](https://data-diff.iflambda.com/latest/nav/dev/contributing.html) for more details or check out [CONTRIBUTING.md](./CONTRIBUTING.md)

🌟 And then, kudos to **our beloved Contributors**:

<a href="https://github.com/infinitelambda/dbt-data-diff/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=infinitelambda/dbt-data-diff" alt="Contributors" />
</a>

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
