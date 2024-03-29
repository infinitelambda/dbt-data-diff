<!-- markdownlint-disable no-inline-html no-alt-text -->
# dbt-data-diff

<img align="right" width="150" height="150" src="./docs/assets/img/il-logo.png">

[![dbt-hub](https://img.shields.io/badge/Visit-dbt--hub%20↗️-FF694B?logo=dbt&logoColor=FF694B)](https://hub.getdbt.com/infinitelambda/data_diff)
[![support-snowflake](https://img.shields.io/badge/support-Snowflake-7faecd?logo=snowflake&logoColor=7faecd)](https://docs.snowflake.com?ref=infinitelambda)
[![support-dbt](https://img.shields.io/badge/support-dbt%20v1.6+-FF694B?logo=dbt&logoColor=FF694B)](https://docs.getdbt.com?ref=infinitelambda)
[![built-in-sis](https://img.shields.io/badge/built--in-SiS-BD4042?logo=streamlit&logoColor=FF694B)](https://www.snowflake.com/en/data-cloud/overview/streamlit-in-snowflake?ref=infinitelambda)

Data-diff solution for dbt-ers with Snowflake ❄️ 🚀

> [!TIP]
> 📖 For more details, please help to visit [the documentation site](https://data-diff.iflambda.com/latest/) (or go to the [docs/index.md](./docs/index.md)) for more details

<img src="./docs/assets/img/data-diff.jpeg" alt="Sample diffing">

## Installation

- Add to `packages.yml` file:

```yml
packages:
  - package: infinitelambda/data_diff
    version: [">=1.0.0", "<1.1.0"]
```

Or use the latest version from git:

```yml
packages:
  - git: "https://github.com/infinitelambda/dbt-data-diff.git"
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

## Quick Demo

Let's jump to the [Quick Start](https://data-diff.iflambda.com/latest/#quick-start) section and the next [demo one](https://data-diff.iflambda.com/latest/#demo) 🏃

📊 Here is the sample Streamlit in Snowflake application based on the result produced by the package:

<img src="./docs/assets/img/sis_ui.png" alt="Sample SiS">

## How to Contribute

`dbt-data-diff` is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

👉 See [CONTRIBUTING guideline](https://data-diff.iflambda.com/latest/nav/dev/contributing.html) for more details or check out [CONTRIBUTING.md](./CONTRIBUTING.md)

🌟 And then, kudos to **our beloved Contributors**:

<a href="https://github.com/infinitelambda/dbt-data-diff/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=infinitelambda/dbt-data-diff" alt="Contributors" />
</a>

⭐ Special Credits to [👱 Attila Berecz](https://www.linkedin.com/in/attila-berecz-a0bb5ba2/) who is the OG Contributor of the Core Concept and all the Snowflake Stored Procedures

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
