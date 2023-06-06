{{ config(
     enabled = var('cms_chronic_conditions_enabled',var('tuva_marts_enabled',True))
   )
}}

select
      claim_id
    , patient_id
    , procedure_date
    , code_type
    , code
    , data_source
from {{ ref('core__procedure') }}