{{ config(
    enabled = var('pqi_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
) }}

select p.pqi_number
 , m.pqi_name
 , e.year_number
 , e.encounter_id
 , e.data_source
 , e.patient_id
 , e.facility_npi
 , e.ms_drg_code
 , e.ms_drg_description
 , e.encounter_start_date
 , e.encounter_end_date
 , e.length_of_stay
 , e.paid_amount
 , '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ref('ahrq_measures__pqi_num_long')}} p 
inner join {{ref('ahrq_measures__stg_pqi_inpatient_encounter')}} e on p.encounter_id = e.encounter_id
and
p.data_source = e.data_source
inner join {{ ref('pqi__measures') }} m on cast(p.pqi_number as {{ dbt.type_string() }})  = m.pqi_number
