{% macro data_diff__poll_status_async(p_invocation_id, poll_times=100, poll_wait_in_s=10) -%}

  {% set namespace = data_diff.get_namespace() %}
  {% set dbt_invocation_id = p_invocation_id | replace("-", "_") %}
  {% set end_task = "data_diff__task_end_" ~ dbt_invocation_id %}

  {% set query -%}

    use schema {{ namespace }};

    call system$wait({{ poll_wait_in_s }}, 'SECONDS');

    select    state -- poll until SUCCEEDED
    from      table(information_schema.task_history(
                task_name => '{{ end_task | upper }}'
              ))
    order by  scheduled_time desc
    limit     1;

  {%- endset %}

  {% for item in range(0, poll_times) %}

    {% set query_state = dbt_utils.get_single_value(query, default="") %}
    {{ log("[RUN] Polling #" ~ item ~ ": " ~ (query_state or 'WAITING'), info=True) }}

    {% if query_state == "SUCCEEDED" %}
      {{ return(none) }}
    {% endif %}

  {% endfor %}


{%- endmacro %}
