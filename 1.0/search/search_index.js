var __index = {"config":{"lang":["en"],"separator":"[\\s\\-,:!=\\[\\]()\"`/]+|\\.(?!\\d)|&[lg]t;|(?!\\b)(?=[A-Z][a-z])","pipeline":["stopWordFilter"]},"docs":[{"location":"index.html","title":"\ud83d\udce6 dbt-data-diff","text":""},{"location":"index.html#dbt-data-diff","title":"dbt-data-diff","text":"<p>Data-diff solution for dbt-ers with Snowflake \u2744\ufe0f \ud83c\udf1f</p> <p>Who is this for?</p> <ul> <li>Primarily for people who want to perform Data-diff validation on the Blue-Green deployment \ud83d\ude80</li> <li>Other good considerations \ud83d\udc4d<ul> <li>UAT validation: data-diff with PROD</li> <li>Code-Refactoring validation: data diff between old vs new</li> <li>Migration to Snowflake: data diff between old vs new (requires to land the old data to Snowflake)</li> <li>CI: future consideration only \u26a0\ufe0f</li> </ul> </li> </ul>"},{"location":"index.html#core-concept","title":"Core Concept \ud83c\udf1f","text":"<p><code>dbt-data-diff</code> package provides the diff results into 3 categories or 3 levels of the diff as follows:</p> <ul> <li>\ud83e\udd49 Key diff (models): Compare the Primary Key (<code>pk</code>) only</li> <li>\ud83e\udd48 Schema diff (models): Compare the list of column's Names and Data Types</li> <li>\ud83e\udd47 Content diff (aka Data diff) (models): Compare all cell values. The columns will be filtered by each table's configuration (<code>include_columns</code> and <code>exclude_columns</code>), and the data can be also filtered by the <code>where</code> config. Behind the scenes, this operation does not require the Primary Key (PK) config, it will perform Bulk Operation (<code>INTERCEPT</code> or <code>MINUS</code>) and make an aggregation to make up the column level's match percentage</li> </ul> <p>Sample diffing: </p> <p>Behind the scenes, this package leverages the \u2744\ufe0f Scripting Stored Procedure which provides the 3 ones correspondingly with 3 categories as above. Moreover, it utilizes the DAG of Tasks to optimize the speed with the parallelism once enabled by configuration \ud83d\ude80</p> <p>Sample DAG:</p> <p></p>"},{"location":"index.html#installation","title":"Installation","text":"<ul> <li>Add to <code>packages.yml</code> file:</li> </ul> <pre><code>packages:\n  - package: infinitelambda/data_diff\n    version: [\"&gt;=1.0.0\", \"&lt;1.1.0\"]\n</code></pre> <p>Or use the latest version from git:</p> <pre><code>packages:\n  - git: \"https://github.com/infinitelambda/dbt-data-diff\"\n    revision: 1.0.0 # 1.0.0b1\n</code></pre> <ul> <li>(Optional) Configure database &amp; schema in <code>dbt_project.yml</code> file:</li> </ul> <pre><code>vars:\n  # (optional) default to `target.database` if not specified\n  data_diff__database: COMMON\n  # (optional) default to `target.schema` if not specified\n  data_diff__schema: DATA_DIFF\n</code></pre> <ul> <li>Create/Migrate the <code>data-diff</code>'s DDL resources</li> </ul> <pre><code>dbt deps\ndbt run -s data_diff --vars '{data_diff__on_migration: true}'\n</code></pre>"},{"location":"index.html#quick-start","title":"Quick Start","text":""},{"location":"index.html#1-configure-the-tables-that-need-comparing-in-dbt_projectyml","title":"1. Configure the tables that need comparing in <code>dbt_project.yml</code>","text":"<p>We're going to use the <code>data_diff__configured_tables</code> variable (Check out the dbt_project.yml/<code>vars</code> section for more details!)</p> <p>For example, we want to compare <code>table_x</code> between PROD db and DEV one:</p> <pre><code>vars:\n  data_diff__configured_tables:\n    - src_db: your_prod\n      src_schema: your_schema\n      src_table: table_x\n      trg_db: your_dev\n      trg_schema: your_schema\n      trg_table: table_x\n      pk: key # multiple columns splitted by comma\n      include_columns: [] # [] to include all\n      exclude_columns: [\"loaded_at\"] # [] to exclude loaded_at field\n</code></pre>"},{"location":"index.html#2-refresh-the-configured-tabless-data","title":"2. Refresh the configured tables's data","text":"<p>We can skip this step if you already did it. If not, let's run the below command:</p> <pre><code>dbt run -s data_diff \\\n  --full-refresh \\\n  --vars '{data_diff__on_migration: true, data_diff__on_migration_data: true, data_diff__full_refresh: true}'\n</code></pre> <p>In the above:</p> <ul> <li><code>--full-refresh</code> and <code>data_diff__full_refresh</code>: To re-create all data-diff models</li> <li><code>data_diff__on_migration: true</code>: To re-create the stored procedures</li> <li><code>data_diff__on_migration_data: true</code>: To reset the configured data</li> </ul>"},{"location":"index.html#3-trigger-the-validation-via-dbt-operation","title":"3. Trigger the validation via dbt operation","text":"<p>Now, let's start the diff run:</p> <pre><code>dbt run-operation data_diff__run        # normal mode, run in sequence, wait unitl finished\n# OR\ndbt run-operation data_diff__run_async  # async mode, parallel, no waiting\ndbt run-operation data_diff__run_async --args '{is_polling_status: true}'\n                                        # async mode, parallel, status polling\n</code></pre> <p>In the Async Mode</p> <p>We leverage the DAG of tasks, therefore the dbt's ROLE will need granting the addtional privilege:</p> <pre><code>use role accountadmin;\ngrant execute task on account to role {{ target.role }};\n</code></pre> \ud83d\udcd6 Or via dbt hook by default (it will run an incremental load for all models) <pre><code># Add into dbt_project.yml file\n\n# normal mode\non-run-end\n  - &gt; # run data-diff hook\n    {% if var(\"data_diff__on_run_hook\", false) %}\n      {{ data_diff.data_diff__run(in_hook=true) }}\n    {% endif %}\n\n# async mode\non-run-end\n  - &gt; # run data-diff hook\n    {% if var(\"data_diff__on_run_hook\", false) %}\n      {{ data_diff.data_diff__run_async(in_hook=true) }}\n    {% endif %}\n</code></pre> <pre><code># terminal\ndbt run -s data_diff --vars '{data_diff__on_run_hook: true}'\n</code></pre>"},{"location":"index.html#4-bonus-deploy-the-helper","title":"4. [Bonus] Deploy the helper \ud83e\udd29","text":"<p>Our helper is the Streamlit in Snowflake (SiS) application which was built on the last diff result in order to help us to have a better examining with the actual result without typing SQL.</p> <p>Let's deploy the Streamlit app by running the dbt command as follows:</p> <pre><code>dbt run-operation sis_deploy__diff_helper\n</code></pre> Sample logs <pre><code>02:44:50  Running with dbt=1.7.4\n02:44:52  Registered adapter: snowflake=1.7.1\n02:44:53  Found 16 models, 2 operations, 21 tests, 0 sources, 0 exposures, 0 metrics, 558 macros, 0 groups, 0 semantic models\n02:44:53  [RUN]: sis_deploy__diff_helper\n02:44:53  query:\n\n    create schema if not exists data_diff.blue_dat_common;\n    create or replace stage data_diff.blue_dat_common.stage_diff_helper\n      directory = ( enable = true )\n      comment = 'Named stage for diff helper SiS appilication';\n\n    PUT file://dbt_packages/data_diff/macros/sis/diff_helper.py @data_diff.blue_dat_common.stage_diff_helper overwrite=true auto_compress=false;\n\n    create or replace streamlit data_diff.blue_dat_common.data_diff_helper\n      root_location = '@data_diff.blue_dat_common.stage_diff_helper'\n      main_file = '/diff_helper.py'\n      query_warehouse = wh_data_diff\n      comment = 'Streamlit app for the dbt-data-diff package';\n\n02:45:02  &lt;agate.MappedSequence: (&lt;agate.Row: ('Streamlit DATA_DIFF_HELPER successfully created.')&gt;)&gt;\n</code></pre> <p>Once it's done, you could access to the app via: Steamlit menu / DATA_DIFF_HELPER or via this quick link:</p> <pre><code>{BASE_SNOWFLAKE_URL}/#/streamlit-apps/{DATABASE}.{SCHEMA}.DATA_DIFF_HELPER\n</code></pre> \ud83d\udc49 Check out the sample app UI"},{"location":"index.html#demo","title":"Demo","text":"<p>Part 1: Configure and prepare Blue/Green</p> <p></p> <p>Part 2: Run data diff &amp; examine the result</p> <p></p>"},{"location":"index.html#variables","title":"Variables","text":"<p>See <code>dbt_project.yml</code> file</p> <p>Go to <code>vars</code> section here \ud83c\udfc3</p> <p>We managed to provide the inline comments only for now, soon to have the dedicated page for more detail explanation.</p> <p>Here are the full list of built-in variables:</p> <ul> <li><code>data_diff__database</code></li> <li><code>data_diff__schema</code></li> <li><code>data_diff__on_migration</code></li> <li><code>data_diff__on_migration_data</code></li> <li><code>data_diff__on_run_hook</code></li> <li><code>data_diff__full_refresh</code></li> <li><code>data_diff__configured_tables__source_fixed_naming</code></li> <li><code>data_diff__configured_tables__target_fixed_naming</code></li> <li><code>data_diff__configured_tables</code></li> <li><code>data_diff__auto_pipe</code></li> </ul>"},{"location":"index.html#how-to-contribute","title":"How to Contribute \u2764\ufe0f","text":"<p><code>dbt-data-diff</code> is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.</p> <p>\ud83d\udc49 See CONTRIBUTING guideline for more details or check out CONTRIBUTING.md</p> <p>\ud83c\udf1f And then, kudos to our beloved Contributors:</p> <p> </p> <p>\u2b50 Special Credits to \ud83d\udc71 Attila Berecz who is the OG Contributor of the Core Concept and all the Snowflake Stored Procedures</p>"},{"location":"index.html#features-comparison-to-the-alternative-packages","title":"Features comparison to the alternative packages","text":"Feature Supported Package Notes Key diff <ul><li><code>dbt_data_diff</code></li><li><code>data_diff</code></li><li><code>dbt_audit_helper</code></li></ul> \u2705 all available Schema diff <ul><li><code>dbt_data_diff</code></li><li><code>data_diff</code>(*)</li><li><code>dbt_audit_helper</code></li></ul> (*): Only available in the paid-version \ud83d\udcb0 Content diff <ul><li><code>dbt_data_diff</code></li><li><code>data_diff</code>(*)</li><li><code>dbt_audit_helper</code></li></ul> (*): Only available in the paid-version \ud83d\udcb0 Yaml Configuration <ul><li><code>dbt_data_diff</code></li></ul> <code>data_diff</code> will use the <code>toml</code> file, <code>dbt_audit_helper</code> will require to create new models for each comparison Query &amp; Execution log <ul><li><code>dbt_data_diff</code></li></ul> Except for dbt's log, this package to be very transparent on which diff queries executed which are exposed in <code>log_for_validation</code> model Snowflake-native Stored Proc <ul><li><code>dbt_data_diff</code></li></ul> Purely built as Snowflake SQL native stored procedures Parallelism <ul><li><code>dbt_data_diff</code></li><li><code>data_diff</code></li><li><code>dbt_audit_helper</code></li></ul> <code>dbt_data_diff</code> leverages Snowflake Task DAG, the others use python threading Asynchronous <ul><li><code>dbt_data_diff</code></li></ul> Trigger run &amp; go away. Decide to continously poll the run status and waiting until finished if needed Multi-warehouse supported <ul><li><code>dbt_data_diff</code>(*)</li><li><code>data_diff</code></li><li><code>dbt_audit_helper</code></li></ul> (*): Future Consideration \ud83c\udfc3"},{"location":"index.html#about-infinite-lambda","title":"About Infinite Lambda","text":"<p>Infinite Lambda is a cloud and data consultancy. We build strategies, help organizations implement them, and pass on the expertise to look after the infrastructure.</p> <p>We are an Elite Snowflake Partner, a Platinum dbt Partner, and a two-time Fivetran Innovation Partner of the Year for EMEA.</p> <p>Naturally, we love exploring innovative solutions and sharing knowledge, so go ahead and:</p> <p>\ud83d\udd27 Take a look around our Git</p> <p>\u270f\ufe0f Browse our tech blog</p> <p>We are also chatty, so:</p> <p>\ud83d\udc40 Follow us on LinkedIn</p> <p>\ud83d\udc4b\ud83c\udffc Or just get in touch</p> <p></p>"},{"location":"contributing.html","title":"Contributing to <code>dbt-data-diff</code>","text":"<p><code>dbt-data-diff</code> is open-source dbt package \u2764\ufe0f. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.</p> <ul> <li>Contributing to <code>dbt-data-diff</code></li> <li>About this document</li> <li>Getting the code<ul> <li>Installing git</li> <li>External contributors</li> </ul> </li> <li>Setting up an environment<ul> <li>Tools</li> <li>Get dbt profile ready</li> </ul> </li> <li>Linting</li> <li>Testing</li> <li>Committing</li> <li>Submitting a Pull Request</li> </ul>"},{"location":"contributing.html#about-this-document","title":"About this document","text":"<p>There are many ways to contribute to the ongoing development of <code>dbt-data-diff</code>, such as by participating in discussions and issues.</p> <p>The rest of this document serves as a more granular guide for contributing code changes to <code>dbt-data-diff</code> (this repository). It is not intended as a guide for using <code>dbt-data-diff</code>, and some pieces assume a level of familiarity with Python development with <code>poetry</code>. Specific code snippets in this guide assume you are using macOS or Linux and are comfortable with the command line.</p> <ul> <li>Branches: All pull requests from community contributors should target the <code>main</code> branch (default). If the change is needed as a patch for a minor version of dbt that has already been released (or is already a release candidate), a maintainer will backport the changes in your PR to the relevant \"latest\" release branch (<code>1.0.&lt;latest&gt;</code>, <code>1.1.&lt;latest&gt;</code>, ...). If an issue fix applies to a release branch, that fix should be first committed to the development branch and then to the release branch (rarely release-branch fixes may not apply to <code>main</code>).</li> <li>Releases: Before releasing a new minor version, we prepare a series of beta release candidates to allow users to test the new version in live environments. This is an important quality assurance step, as it exposes the new code to a wide variety of complicated deployments and can surface bugs before official release. Releases are accessible via pip.</li> </ul>"},{"location":"contributing.html#getting-the-code","title":"Getting the code","text":""},{"location":"contributing.html#installing-git","title":"Installing git","text":"<p>You will need <code>git</code> in order to download and modify the <code>dbt-data-diff</code> source code. On macOS, the best way to download git is to just install Xcode.</p>"},{"location":"contributing.html#external-contributors","title":"External contributors","text":"<p>You can contribute to <code>dbt-data-diff</code> by forking the <code>dbt-data-diff</code> repository. For a detailed overview on forking, check out the GitHub docs on forking. In short, you will need to:</p> <ol> <li>Fork the <code>dbt-data-diff</code> repository</li> <li>Clone your fork locally</li> <li>Check out a new branch for your proposed changes</li> <li>Push changes to your fork</li> <li>Open a pull request against <code>infintelambda/dbt-data-diff</code> from your forked repository</li> </ol>"},{"location":"contributing.html#setting-up-an-environment","title":"Setting up an environment","text":"<p>There are some tools that will be helpful to you in developing locally. While this is the list relevant for <code>dbt-data-diff</code> development, many of these tools are used commonly across open-source python projects.</p>"},{"location":"contributing.html#tools","title":"Tools","text":"<p>We will buy <code>poetry</code> in <code>dbt-data-diff</code> development and testing.</p> <p>So first install poetry via pip or via the official installer, please help to check right version used in poetry.lock file. Then, start installing the local environment:</p> <pre><code>poetry install\npoetry shell\npoe git-hooks\n</code></pre>"},{"location":"contributing.html#get-dbt-profile-ready","title":"Get dbt profile ready","text":"<p>Please help to check the sample script to initialize Snowflake environment in <code>integreation_tests/ci</code> directory, and get your database freshly created.</p> <p>Next, you should follow dbt profile instruction and setting up your dedicated profile. Again, you could try our sample in the same above directory.</p> <p>Run <code>poe data-diff-verify</code> for verifying the connection \u2705</p>"},{"location":"contributing.html#linting","title":"Linting","text":"<p>We're trying to also maintain the code quality leveraging sqlfluff.</p> <p>It is highly encouraged that you format the code before commiting using the below <code>poe</code> helpers:</p> <pre><code>poe lint    # check your code, we run this check in CI\npoe format  # format your code to match sqlfluff configs\n</code></pre>"},{"location":"contributing.html#testing","title":"Testing","text":"<p>Once you're able to manually test that your code change is working as expected, it's important to run existing automated tests, as well as adding some new ones. These tests will ensure that:</p> <ul> <li>Your code changes do not unexpectedly break other established functionality</li> <li>Your code changes can handle all known edge cases</li> <li>The functionality you're adding will keep working in the future</li> </ul> <p>See here for details for running existing integration tests and adding new ones:</p> <p>An integration test typically involves making 1) a new seed file 2) a new model file 3) a generic test to assert anticipated behaviour.</p> <p>Once you've added all of these files, in the <code>poetry shell</code>, you should be able to run:</p> <pre><code>poe data-diff-migration # create resources\npoe data-diff-bg        # prepare blue/green data\npoe data-diff-run       # trigger the data-diff\npoe data-diff-test      # test the package and the data-diff result\n</code></pre> <p>Alternatively, you could use 1 single command: <code>poe data-diff-run</code> OR <code>poe data-diff-ru-async-wait</code>\ud83d\udc4d</p>"},{"location":"contributing.html#committing","title":"Committing","text":"<p>Upon running <code>poe git-hooks</code> we will make sure that you provide as the clean &amp; neat commit messages as possible.</p> <p>There are 2 main checks:</p> <ul> <li>Trailing whitespace: If any, it will try to fix it for us, and we have to stage the changes before committing</li> <li>Commit message: It must follow the commitizen convention as <code>{change_type}: {message}</code></li> <li><code>change_type</code>: is one of <code>feat|fix|chore|refactor|perf|BREAKING CHANGE</code></li> </ul>"},{"location":"contributing.html#submitting-a-pull-request","title":"Submitting a Pull Request","text":"<p>Code can be merged into the current development branch <code>main</code> by opening a pull request. A <code>dbt-data-diff</code> maintainer will review your PR. They may suggest code revision for style or clarity, or request that you add unit or integration test(s). These are good things! We believe that, with a little bit of help, anyone can contribute high-quality code.</p> <p>Automated tests run via GitHub Actions. If you're a first-time contributor, all tests (including code checks and unit tests) will require a maintainer to approve. Changes in the <code>dbt-data-diff</code> repository trigger integration tests against Snowflake \ud83d\udcb0.</p> <p>Once all tests are passing and your PR has been approved, a <code>dbt-data-diff</code> maintainer will merge your changes into the active development branch. And that's it!</p> <p>Happy Developing \ud83c\udf89</p>"}]}