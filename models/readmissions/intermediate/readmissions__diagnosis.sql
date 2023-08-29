{{ config(
     enabled = var('readmissions_enabled',var('claims_enabled',var('tuva_marts_enabled',False)))
   )
}}

-- Staging model for the input layer:
-- stg_diagnosis input layer model.
-- This contains one row for every unique diagnosis each patient has.

select distinct
    cast(a.encounter_id as {{ dbt.type_string() }}) as encounter_id
,   cast(a.normalized_code as {{ dbt.type_string() }}) as diagnosis_code
,   cast(a.condition_rank as integer) as diagnosis_rank
, '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ ref('readmissions__stg_core__condition') }} a
inner join  {{ ref('readmissions__stg_core__encounter') }} b
  on a.encounter_id = b.encounter_id
where normalized_code_type = 'icd-10-cm'
