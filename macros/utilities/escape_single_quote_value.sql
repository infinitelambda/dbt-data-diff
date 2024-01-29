{% macro escape_single_quote_value(value) %}

  {{ return(value | replace("'", "''")) }}

{% endmacro %}
