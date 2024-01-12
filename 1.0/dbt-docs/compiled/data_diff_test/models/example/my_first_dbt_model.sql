/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/



with source_data as (

    select 1 as id, 'id 1' as id_description
    union all
    select null as id, 'null' as id_description
    union all
    select 2 as id, 'id 2' as id_description
    union all
    select 3 as id, 'id 3 blue'as id_description
    
    union all
    select 4 as id, 'id 4' as id_description
    

)

select *
from source_data

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null