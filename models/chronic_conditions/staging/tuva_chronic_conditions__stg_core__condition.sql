{{ config(
     enabled = var('tuva_chronic_conditions_enabled',var('tuva_marts_enabled',True))
   )
}}


select 
  patient_id
, code
, condition_date
from {{ ref('core__condition')}}