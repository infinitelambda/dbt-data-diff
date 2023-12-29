{% macro data_diff__poll_status_async(p_invocation_id, poll_times=10, poll_wait_in_s=10) -%}

  {% set namespace = data_diff.get_namespace() %}
  {% set dbt_invocation_id = p_invocation_id | replace("-", "_") %}
  {% set end_task = "data_diff__task_end_" ~ dbt_invocation_id %}

  {% set query -%}

    use schema {{ namespace }};

    select    state -- poll until SUCCEEDED
    from      table(information_schema.task_history(
                task_name => '{{ end_task | upper }}'
              ))
    order by  scheduled_time desc
    limit     1;

    call system$wait({{ poll_wait_in_s }}, 'SECONDS');

  {%- endset %}

  {% for item in poll_times %}

    {% set query_state = dbt_utils.get_single_value(query, default="") %}
    {{ log("Polling #" ~ item ~ ": " ~ query_state, info=True) }}

    {% if item == "SUCCEEDED" %}
      {{ return() }}
    {% endif %}

  {% endfor %}


{%- endmacro %}
