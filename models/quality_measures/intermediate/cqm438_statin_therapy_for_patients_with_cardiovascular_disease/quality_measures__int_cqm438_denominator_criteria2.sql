{{ config(
     enabled = var('quality_measures_enabled',var('claims_enabled',var('clinical_enabled',var('tuva_marts_enabled',False)))) | as_bool
   )
}}

with visit_codes as (

    select
          value_sets.code
        , value_sets.code_system
    from {{ ref('quality_measures__value_sets') }} value_sets
    inner join {{ ref('quality_measures__concepts') }} concepts
        on value_sets.concept_name = concepts.concept_name
            and concepts.measure_id = 'CQM438'

)

, visits_encounters as (

    select patient_id
         , coalesce(encounter.encounter_start_date,encounter.encounter_end_date) as min_date
         , coalesce(encounter.encounter_end_date,encounter.encounter_start_date) as max_date
    from {{ref('quality_measures__stg_core__encounter')}} encounter
    inner join {{ref('quality_measures__int_cqm438__performance_period')}} as pp
        on coalesce(encounter.encounter_end_date,encounter.encounter_start_date) >= pp.performance_period_begin
        and  coalesce(encounter.encounter_start_date,encounter.encounter_end_date) <= pp.performance_period_end
    where lower(encounter_type) in (
          'home health'
        , 'office visit'
        , 'outpatient'
        , 'outpatient rehabilitation'
        , 'telehealth'
     )

)

, procedure_encounters as (

    select 
          patient_id
        , procedure_date as min_date
        , procedure_date as max_date
    from {{ref('quality_measures__stg_core__procedure')}} proc
    inner join {{ref('quality_measures__int_cqm438__performance_period')}}  as pp
        on procedure_date between pp.performance_period_begin and  pp.performance_period_end
    inner join visit_codes
        on coalesce(proc.normalized_code,proc.source_code) = visit_codes.code

)

, claims_encounters as (
    
    select patient_id
    , coalesce(claim_start_date,claim_end_date) as min_date
    , coalesce(claim_end_date,claim_start_date) as max_date
    from {{ref('quality_measures__stg_medical_claim')}} medical_claim
    inner join {{ref('quality_measures__int_cqm438__performance_period')}}  as pp on
        coalesce(claim_end_date,claim_start_date)  >=  pp.performance_period_begin
         and coalesce(claim_start_date,claim_end_date) <=  pp.performance_period_end
    inner join visit_codes
        on medical_claim.hcpcs_code= visit_codes.code

)

, all_encounters as (

    select *, 'v' as visit_enc,cast(null as {{ dbt.type_string() }}) as proc_enc, cast(null as {{ dbt.type_string() }}) as claim_enc
    from visits_encounters

    union all

    select *, cast(null as {{ dbt.type_string() }}) as visit_enc, 'p' as proc_enc, cast(null as {{ dbt.type_string() }}) as claim_enc
    from procedure_encounters

    union all
    
    select *, cast(null as {{ dbt.type_string() }}) as visit_enc,cast(null as {{ dbt.type_string() }}) as proc_enc, 'c' as claim_enc
    from claims_encounters

)

, encounters_by_patient as (

    select patient_id,min(min_date) min_date, max(max_date) max_date,
        concat(concat(
            coalesce(min(visit_enc),'')
            ,coalesce(min(proc_enc),''))
            ,coalesce(min(claim_enc),'')
            ) as qualifying_types
    from all_encounters
    group by patient_id

)

, cholesterol_codes as (

    select
          code
        , code_system
        , concept_name
    from {{ ref('quality_measures__value_sets') }}
    where lower(concept_name) in (
              'ldl cholesterol'
            , 'familial hypercholesterolemia'
        )

)

, conditions as (

    select
          patient_id
        , claim_id
        , encounter_id
        , recorded_date
        , source_code
        , source_code_type
        , normalized_code
        , normalized_code_type
    from {{ ref('quality_measures__stg_core__condition')}}

)

, cholesterol_conditions as (

    select
          conditions.patient_id
        , conditions.recorded_date as evidence_date
    from conditions
    inner join cholesterol_codes
        on conditions.source_code_type = cholesterol_codes.code_system
            and conditions.source_code = cholesterol_codes.code

)

, procedures as (

    select
          patient_id
        , procedure_date
        , coalesce (
              normalized_code_type
            , case
                when lower(source_code_type) = 'cpt' then 'hcpcs'
                when lower(source_code_type) = 'snomed' then 'snomed-ct'
                else lower(source_code_type)
              end
          ) as code_type
        , coalesce(
              normalized_code
            , source_code
          ) as code
    from {{ ref('quality_measures__stg_core__procedure') }}

)

, cholesterol_procedures as (

    select
          procedures.patient_id
        , procedures.procedure_date as evidence_date
    from procedures
         inner join cholesterol_codes
             on procedures.code = cholesterol_codes.code
             and procedures.code_type = cholesterol_codes.code_system

)

, labs as (
    select
        patient_id
        , result
        , result_date
        , collection_date
        , source_code_type
        , source_code
        , normalized_code_type
        , normalized_code
    from {{ ref('quality_measures__stg_core__lab_result')}}

)

, cholesterol_tests_with_result as (
    select
      labs.patient_id
    , labs.result as evidence_value
    , coalesce(collection_date,result_date) as evidence_date
    , cholesterol_codes.concept_name
    , row_number() over(partition by labs.patient_id order by labs.result desc) as rn
    from labs
    inner join cholesterol_codes
      on ( labs.normalized_code = cholesterol_codes.code
       and labs.normalized_code_type = cholesterol_codes.code_system )
      or ( labs.source_code = cholesterol_codes.code
       and labs.source_code_type = cholesterol_codes.code_system )
        and {{ apply_regex('labs.result', '[+-]?([0-9]*[.])?[0-9]+') }}

)

, cholesterol_labs as (

    select 
          patient_id
        , evidence_date
    from cholesterol_tests_with_result
    where rn= 1 
        and evidence_value > 190

)

, all_patients_with_cholesterol as (

    select
          cholesterol_conditions.patient_id
        , cholesterol_conditions.evidence_date
    from cholesterol_conditions

    union all

    select
          cholesterol_procedures.patient_id
        , cholesterol_procedures.evidence_date
    from cholesterol_procedures

    union all

    select
          cholesterol_labs.patient_id
        , cholesterol_labs.evidence_date
    from cholesterol_labs

)

, patients_with_cholesterol as (

    select
          patient_id
        , performance_period_begin
        , performance_period_end
        , measure_id
        , measure_name
        , measure_version 
    from all_patients_with_cholesterol
    inner join {{ref('quality_measures__int_cqm438__performance_period')}} pp
    on evidence_date <= pp.performance_period_end

)

, qualifying_patients_with_age as (

    select
          p.patient_id
        , floor({{ datediff('birth_date', 'performance_period_begin', 'hour') }} / 8760.0)  as age
        , performance_period_begin
        , performance_period_end
        , measure_id
        , measure_name
        , measure_version 
    from {{ref('quality_measures__stg_core__patient')}} p
    inner join patients_with_cholesterol e
        on p.patient_id = e.patient_id
            and p.death_date is null

)

, qualifying_patients as (

    select
        distinct
          qualifying_patients_with_age.patient_id
        , qualifying_patients_with_age.age as age
        , performance_period_begin
        , performance_period_end
        , measure_id
        , measure_name
        , measure_version
        , 1 as denominator_flag
    from qualifying_patients_with_age
    where age between 20 and 75

)

, add_data_types as (

    select
          cast(patient_id as {{ dbt.type_string() }}) as patient_id
        , cast(age as integer) as age
        , cast(performance_period_begin as date) as performance_period_begin
        , cast(performance_period_end as date) as performance_period_end
        , cast(measure_id as {{ dbt.type_string() }}) as measure_id
        , cast(measure_name as {{ dbt.type_string() }}) as measure_name
        , cast(measure_version as {{ dbt.type_string() }}) as measure_version
        , cast(denominator_flag as integer) as denominator_flag
    from qualifying_patients

)

select 
      patient_id
    , age
    , performance_period_begin
    , performance_period_end
    , measure_id
    , measure_name
    , measure_version
    , denominator_flag
    , '{{ var('tuva_last_run')}}' as tuva_last_run
from add_data_types