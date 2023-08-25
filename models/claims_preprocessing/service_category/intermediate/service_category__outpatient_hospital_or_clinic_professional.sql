{{ config(
     enabled = var('service_category_grouper_enabled',var('tuva_marts_enabled',True))
   )
}}

select distinct 
  claim_id
, claim_line_number
, 'Outpatient Hospital or Clinic' as service_category_2
, '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ ref('service_category__stg_medical_claim') }}
where claim_type = 'professional'
  and place_of_service_code in ('15','17','19','22','49','50','60','71','72')
  