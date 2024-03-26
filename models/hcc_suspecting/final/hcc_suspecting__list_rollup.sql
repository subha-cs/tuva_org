{{ config(
     enabled = var('hcc_suspecting_enabled',var('claims_enabled',var('clinical_enabled',var('tuva_marts_enabled',False)))) | as_bool
   )
}}

with list as (

    select
          patient_id
        , data_source
        , hcc_code
        , hcc_description
        , reason
        , contributing_factor
        , condition_date
        , row_number() over (
            partition by
                  patient_id
                , hcc_code
            order by condition_date desc
          ) as row_num
    from {{ ref('hcc_suspecting__list') }}

)

, list_dedupe as (

    select
          patient_id
        , hcc_code
        , hcc_description
        , reason
        , contributing_factor
        , condition_date as latest_condition_date
    from list
    where row_num = 1

)

, add_data_types as (

    select
          cast(patient_id as {{ dbt.type_string() }}) as patient_id
        , cast(hcc_code as {{ dbt.type_string() }}) as hcc_code
        , cast(hcc_description as {{ dbt.type_string() }}) as hcc_description
        , cast(reason as {{ dbt.type_string() }}) as reason
        , cast(contributing_factor as {{ dbt.type_string() }}) as contributing_factor
        , cast(latest_condition_date as date) as latest_condition_date
    from list_dedupe

)

select
      patient_id
    , hcc_code
    , hcc_description
    , reason
    , contributing_factor
    , latest_condition_date
    , '{{ var('tuva_last_run')}}' as tuva_last_run
from add_data_types