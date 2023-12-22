<!-- markdownlint-disable no-inline-html -->
# dbt-data-diff

Data-diff solution for dbt-ers with Snowflake ❄️ 🚀

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
  <summary>Click me</summary>

In the above:

- `--full-refresh` and `data_diff__full_refresh`: To re-create all data-diff models
- `data_diff__on_migration: true`: To re-create the stored procedures
- `data_diff__on_migration_data: true`: To reset the configured data

</details>

## Quick Demo

Trigger the validation:

- Via dbt operation:

```bash
dbt run-operation data_diff__run[_async]
```

<details> <!-- markdownlint-disable no-inline-html -->
  <summary>Or via dbt hook by default (it will run an incremental load for all models)</summary>

```bash
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
