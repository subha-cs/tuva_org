{{ config(
     enabled = var('service_category_grouper_enabled',var('tuva_marts_enabled',True))
   )
}}

select distinct 
  claim_id
, 'Home Health' as service_category_2
from {{ ref('service_category__stg_medical_claim') }}
where claim_type = 'institutional'
  and left(bill_type_code,2) in ('31','32','33')
  