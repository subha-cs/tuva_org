{{ config(
     enabled = var('service_category_grouper_enabled',var('tuva_marts_enabled',True))
   )
}}

select distinct 
  claim_id
, claim_line_number
, 'Durable Medical Equipment' as service_category_2
from {{ ref('service_category__stg_medical_claim') }}
where claim_type = 'professional'
  and hcpcs_code between 'E0100' and 'E8002'
  