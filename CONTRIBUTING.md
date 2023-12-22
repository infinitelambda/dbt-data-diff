# Contributing to `dbt-data-diff`

`dbt-data-diff` is open-source dbt package ❤️. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

- [Contributing to `dbt-data-diff`](#contributing-to-dbt-data-diff)
  - [About this document](#about-this-document)
  - [Getting the code](#getting-the-code)
    - [Installing git](#installing-git)
    - [External contributors](#external-contributors)
  - [Setting up an environment](#setting-up-an-environment)
    - [Tools](#tools)
    - [Get dbt profile ready](#get-dbt-profile-ready)
  - [Linting](#linting)
  - [Testing](#testing)
  - [Committing](#committing)
  - [Submitting a Pull Request](#submitting-a-pull-request)

## About this document

There are many ways to contribute to the ongoing development of `dbt-data-diff`, such as by participating in discussions and issues.

The rest of this document serves as a more granular guide for contributing code changes to `dbt-data-diff` (this repository). It is not intended as a guide for using `dbt-data-diff`, and some pieces assume a level of familiarity with Python development with `poetry`. Specific code snippets in this guide assume you are using macOS or Linux and are comfortable with the command line.

- **Branches:** All pull requests from community contributors should target the `main` branch (default). If the change is needed as a patch for a minor version of dbt that has already been released (or is already a release candidate), a maintainer will backport the changes in your PR to the relevant "latest" release branch (`1.0.<latest>`, `1.1.<latest>`, ...). If an issue fix applies to a release branch, that fix should be first committed to the development branch and then to the release branch (rarely release-branch fixes may not apply to `main`).
- **Releases**: Before releasing a new minor version, we prepare a series of beta release candidates to allow users to test the new version in live environments. This is an important quality assurance step, as it exposes the new code to a wide variety of complicated deployments and can surface bugs before official release. Releases are accessible via pip.

## Getting the code

### Installing git

You will need `git` in order to download and modify the `dbt-data-diff` source code. On macOS, the best way to download git is to just install [Xcode](https://developer.apple.com/support/xcode/).

### External contributors

You can contribute to `dbt-data-diff` by forking the `dbt-data-diff` repository. For a detailed overview on forking, check out the [GitHub docs on forking](https://help.github.com/en/articles/fork-a-repo). In short, you will need to:

1. Fork the `dbt-data-diff` repository
2. Clone your fork locally
3. Check out a new branch for your proposed changes
4. Push changes to your fork
5. Open a pull request against `infintelambda/dbt-data-diff` from your forked repository

## Setting up an environment

There are some tools that will be helpful to you in developing locally. While this is the list relevant for `dbt-data-diff` development, many of these tools are used commonly across open-source python projects.

### Tools

We will buy `poetry` in `dbt-data-diff` development and testing.

So first install poetry via pip or via the [official installer](https://python-poetry.org/docs/#installing-with-the-official-installer), please help to check right version used in [poetry.lock](/poetry.lock) file. Then, start installing the local environment:

```bash
poetry install
poetry shell
poe git-hooks
```

### Get dbt profile ready

Please help to check [the sample script](/integration_tests/ci/sf-init.sql) to initialize Snowflake environment in `integreation_tests/ci` directory, and get your database freshly created.

Next, you should follow [dbt profile instruction](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles) and setting up your dedicated profile. Again, you could [try our sample](/integration_tests/ci/profiles.yml) in the same above directory.

Run `poe data-diff-verify` for verifying the connection ✅

## Linting

We're trying to also maintain the code quality leveraging [sqlfluff](https://sqlfluff.com/).

It is highly encouraged that you format the code before commiting using the below `poe` helpers:

```bash
poe lint    # check your code, we run this check in CI
poe format  # format your code to match sqlfluff configs
```

## Testing

Once you're able to manually test that your code change is working as expected, it's important to run existing automated tests, as well as adding some new ones. These tests will ensure that:

- Your code changes do not unexpectedly break other established functionality
- Your code changes can handle all known edge cases
- The functionality you're adding will _keep_ working in the future

See here for details for running existing integration tests and adding new ones:

**An integration test typically involves making 1) a new seed file 2) a new model file 3) a generic test to assert anticipated behaviour.**

Once you've added all of these files, in the `poetry shell`, you should be able to run:

```bash
poe data-diff-migration # create resources
poe data-diff-bg        # prepare blue/green data
poe data-diff-run       # trigger the data-diff
poe data-diff-test      # test the package and the data-diff result
```

Alternatively, you could use 1 single command: `poe data-diff` 👍

## Committing

Upon running `poe git-hooks` we will make sure that you provide as the clean & neat commit messages as possible.

There are 2 main checks:

- Trailing whitespace: If any, it will try to fix it for us, and we have to stage the changes before committing
- Commit message: It must follow the [commitizen](https://commitizen-tools.github.io/commitizen/) convention as `{change_type}: {message}`
  - `change_type`: is one of `feat|fix|chore|refactor|perf|BREAKING CHANGE`

## Submitting a Pull Request

Code can be merged into the current development branch `main` by opening a pull request. A `dbt-data-diff` maintainer will review your PR. They may suggest code revision for style or clarity, or request that you add unit or integration test(s). These are good things! We believe that, with a little bit of help, anyone can contribute high-quality code.

Automated tests run via GitHub Actions. If you're a first-time contributor, all tests (including code checks and unit tests) will require a maintainer to approve. Changes in the `dbt-data-diff` repository trigger integration tests against Postgres. dbt Labs also provides CI environments in which to test changes to other adapters, triggered by PRs in those adapters' repositories, as well as periodic maintenance checks of each adapter in concert with the latest `dbt-data-diff` code changes.

Once all tests are passing and your PR has been approved, a `dbt-data-diff` maintainer will merge your changes into the active development branch. And that's it!

**_Happy Developing 🎉_**
