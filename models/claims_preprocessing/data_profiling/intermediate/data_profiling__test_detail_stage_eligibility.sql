{{ config(
     enabled = var('data_profiling_enabled',var('tuva_marts_enabled',True))
   )
}}


select distinct
        source_table
        , claim_type
        , grain
        , patient_id
        , test_category
        , test_name 
    from {{ ref('data_profiling__eligibility_duplicates') }}
    union all
    select distinct
        source_table
        , claim_type
        , grain
        , patient_id
        , test_category
        , test_name 
    from {{ ref('data_profiling__eligibility_missing_values') }}
    union all
    select distinct
        source_table
        , claim_type
        , grain
        , patient_id
        , test_category
        , test_name 
    from {{ ref('data_profiling__eligibility_invalid_values') }}
    union all
    select distinct
        source_table
        , claim_type
        , grain
        , patient_id
        , test_category
        , test_name 
    from {{ ref('data_profiling__eligibility_plausibility') }}