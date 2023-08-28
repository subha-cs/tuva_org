{{ config(
     enabled = var('medical_records_enabled',var('tuva_marts_enabled',False))
   )
}}


select
    observation_id
    , patient_id
    , encounter_id
    , panel_id
    , observation_date
    , observation_type
    , source_code_type
    , source_code
    , source_description
    , normalized_code_type
    , normalized_code
    , normalized_description
    , result
    , source_units
    , normalized_units
    , source_reference_range_low
    , source_reference_range_high
    , normalized_reference_range_low
    , normalized_reference_range_high
    , data_source
    , tuva_last_run
from {{ ref('core_stage_clinical__observation') }}