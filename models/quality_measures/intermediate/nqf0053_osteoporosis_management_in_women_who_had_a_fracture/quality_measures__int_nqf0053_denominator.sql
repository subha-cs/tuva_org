{{ config(
     enabled = var('quality_measures_enabled',var('claims_enabled',var('clinical_enabled',var('tuva_marts_enabled',False))))
     | as_bool
   )
}}

with visit_codes as (

    select
          code
        , code_system
    from {{ ref('quality_measures__value_sets') }} as value_sets
    where concept_name in (
          'office visit'
        , 'home healthcare services'
        , 'preventive care services established office visit, 18 and up'
        , 'preventive care services initial office visit, 18 and up'
        , 'annual wellness visit'
        , 'emergency department evaluation and management visit'
        , 'emergency department visit'
    )

)

, visits_encounters as (

    select 
           patient_id
         , coalesce(encounter.encounter_start_date,encounter.encounter_end_date) as min_date
         , coalesce(encounter.encounter_end_date,encounter.encounter_start_date) as max_date
    from {{ref('quality_measures__stg_core__encounter')}} as encounter
    inner join {{ ref('quality_measures__int_cqm236__performance_period') }} as pp
        on coalesce(encounter.encounter_end_date,encounter.encounter_start_date) >= pp.performance_period_begin
        and  coalesce(encounter.encounter_start_date,encounter.encounter_end_date) <= pp.performance_period_end
    where lower(encounter_type) in (
          'home health'
        , 'office visit'
        , 'outpatient'
        , 'outpatient rehabilitation'
        , 'acute inpatient'
    )
)

, procedure_encounters as (

    select 
          patient_id
        , procedure_date as min_date
        , procedure_date as max_date
    from {{ref('quality_measures__stg_core__procedure')}} proc
    inner join {{ref('quality_measures__int_cqm236__performance_period')}}  as pp
        on procedure_date between pp.performance_period_begin and  pp.performance_period_end
    inner join  visit_codes
        on coalesce(proc.normalized_code,proc.source_code) = visit_codes.code

)

, claims_encounters as (

    select 
          patient_id
        , coalesce(claim_start_date,claim_end_date) as min_date
        , coalesce(claim_end_date,claim_start_date) as max_date
    from {{ref('quality_measures__stg_medical_claim')}} medical_claim
    inner join {{ref('quality_measures__int_cqm236__performance_period')}}  as pp on
        coalesce(claim_end_date,claim_start_date)  >=  pp.performance_period_begin
         and coalesce(claim_start_date,claim_end_date) <=  pp.performance_period_end
    inner join  visit_codes
        on medical_claim.hcpcs_code= visit_codes.code
    where medical_claim.place_of_service_code not in ('21')


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
    select
          patient_id
        , min(min_date) min_date
        , max(max_date) max_date
        , concat(concat(
            coalesce(min(visit_enc),'')
            ,coalesce(min(proc_enc),''))
            ,coalesce(min(claim_enc),'')
            ) as qualifying_types
    from all_encounters
    group by patient_id

)

, bone_fracture_codes as (

    select
          code
        , code_system
    from {{ ref('quality_measures__value_sets') }}
    where lower(concept_name) = 'fracture diagnoses'

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

, bone_fracture_conditions as (

    select
          conditions.patient_id
        , conditions.claim_id
        , conditions.encounter_id
        , conditions.recorded_date
        , conditions.source_code
        , conditions.source_code_type
    from conditions
    inner join bone_fracture_codes
        on conditions.source_code_type = bone_fracture_codes.code_system
            and conditions.source_code = bone_fracture_codes.code

)

, patients_with_age as (
    select
          p.patient_id
        , p.sex
        , min_date
        , floor({{ datediff('birth_date', 'e.min_date', 'hour') }} / 8760.0)  as min_age
        , max_date
        , floor({{ datediff('birth_date', 'e.max_date', 'hour') }} / 8760.0) as max_age
        , qualifying_types
    from {{ref('quality_measures__stg_core__patient')}} p
    inner join encounters_by_patient e
        on p.patient_id = e.patient_id
    where p.death_date is null

)

-- Patients 18-85 years of age who had a visit and diagnosis of essential hypertension starting before and continuing into, or starting during the first six months of the measurement period.
, qualifying_patients as (

    select
        distinct
          bone_fracture_conditions.patient_id
        , bone_fracture_conditions.recorded_date
        , patients_with_age.max_age as age
        , pp.performance_period_begin
        , pp.performance_period_end
        , pp.measure_id
        , pp.measure_name
        , pp.measure_version
        , 1 as denominator_flag
    from bone_fracture_conditions
    left join patients_with_age
        on bone_fracture_conditions.patient_id = patients_with_age.patient_id
    cross join {{ref('quality_measures__int_nqf0053__performance_period')}} pp
    where max_age >= 50 and min_age <=  85
        and bone_fracture_conditions.recorded_date between
            {{ dbt.dateadd (
              datepart = "month"
            , interval = -6
            , from_date_or_timestamp = "lookback_period"
            )
            }}
            and
                pp.lookback_period
        and lower(patients_with_age.sex) = 'female'

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
