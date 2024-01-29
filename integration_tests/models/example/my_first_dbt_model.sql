
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='table') }}

with source_data as (

    select 1 as id, 'id 1' as id_description, {% if target.name.lower() == 'blue' %} '100' {%else %} 100 {% endif %} as amount
    union all
    select null as id, 'null' as id_description, {% if target.name.lower() == 'blue' %} '100' {%else %} 100 {% endif %} as amount
    union all
    select 2 as id, 'id 2' as id_description, {% if target.name.lower() == 'blue' %} '100' {%else %} 100 {% endif %} as amount
    union all
    select 3 as id, {% if target.name.lower() == 'blue' %}'id 3 blue'{% else %}'id 3 green'{% endif %}as id_description, {% if target.name.lower() == 'blue' %} '100' {%else %} 100 {% endif %} as amount
    {% if target.name.lower() == 'blue' %}
    union all
    select 4 as id, 'id 4' as id_description, {% if target.name.lower() == 'blue' %} '100' {%else %} 100 {% endif %} as amount
    {% endif %}

)

select *
from source_data

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
