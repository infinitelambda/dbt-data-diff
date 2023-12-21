use role sysadmin;
use warehouse wh_compute;
create or replace database data_diff with comment = 'Database for data_diff';

use role accountadmin;
create or replace resource monitor rm_data_diff with
  credit_quota = 1
  frequency = daily
  start_timestamp = immediately
  notify_users = ("<YOUR_USER>")
  triggers
    on 100 percent do suspend_immediate
;

create or replace warehouse wh_data_diff with
  warehouse_type = 'standard'
  warehouse_size = 'xsmall'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
  resource_monitor = rm_data_diff
  comment = 'Warehouse for data_diff';

use role securityadmin;
create or replace role role_data_diff with comment = 'Role for data_diff';

grant usage on warehouse wh_data_diff to role role_data_diff;
grant usage on database data_diff to role role_data_diff;
grant all privileges on database data_diff to role role_data_diff;
grant all privileges on all schemas in database data_diff to role role_data_diff;
grant all privileges on future schemas in database data_diff to role role_data_diff;
grant all privileges on all tables in database data_diff to role role_data_diff;
grant all privileges on future tables in database data_diff to role role_data_diff;
grant all privileges on all views in database data_diff to role role_data_diff;
grant all privileges on future views in database data_diff to role role_data_diff;
grant usage, create schema on database data_diff to role role_data_diff;
grant role role_data_diff to role sysadmin;

use role role_data_diff;
use database data_diff;
