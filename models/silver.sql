
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='view') }}

with customerstbl as (
    
  select
    ID,
    FIRST_NAME,
    LAST_NAME
  from {{ source('jaffle_shop','CUSTOMERS') }}
  
),

orderstbl as (

  select
    ID,
    USER_ID,
    cast(ORDER_DATE as DATE) as ORDER_DATE,
    STATUS
  from {{ source('jaffle_shop','ORDERS') }}
  
),

paymentstbl as (

  select
    ID,
    ORDER_ID,
    PAYMENT_METHOD,
    AMOUNT
  from {{ source('jaffle_shop','PAYMENTS') }}
  
)

select *
from customerstbl
inner join orderstbl
  on customerstbl.ID = orderstbl.USER_ID
inner join paymentstbl
  on orderstbl.ID = paymentstbl.ORDER_ID

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
