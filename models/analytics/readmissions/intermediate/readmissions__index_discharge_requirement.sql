
-- Here we list encounter_ids that meet
-- the discharge_disposition_code requirements to be an
-- index admission:
--    *** Must NOT be discharged to another acute care hospital
--    *** Must NOT have left against medical advice
--    *** Patient must be alive at discharge


{{ config(enabled=var('readmissions_enabled',var('tuva_packages_enabled',True))) }}




with all_invalid_discharges as (
select encounter_id
from {{ ref('readmissions__stg_encounter') }}
where discharge_disposition_code in (
     '02' -- Patient discharged/transferred to other short term general hospital for inpatient care.
    ,'07' -- Patient left against medical advice
    ,'20' -- Patient died
    )
)

-- All discharges that meet the discharge_disposition_code
-- requirements to be an index admission
select a.encounter_id
from {{ ref('readmissions__stg_encounter') }} a
left join all_invalid_discharges b
    on a.encounter_id = b.encounter_id
where b.encounter_id is null