{{ config(
     enabled = var('ccsr_enabled',var('claims_enabled',var('clinical_enabled',var('tuva_marts_enabled',False))))
   )
}}

{% set categories_list = dbt_utils.get_column_values(
        table=ref("ccsr__procedure_category_map"),
        column="ccsr_category",
        order_by="ccsr_category"
) %}

with dedupe_records as (

    select distinct
        encounter_id,
        patient_id,
        ccsr_category
    from {{ ref('ccsr__long_procedure_category') }} 

)

select
    encounter_id,
    patient_id,
    -- pivot rows into column values for each possible CCSR category
    {% for category in categories_list %}
    -- as we don't rank procedure codes, we encode to 0 or 1 instead of 0-3
    sum(case when ccsr_category = '{{ category }}' then 1 else 0 end) as prccsr_{{ category|lower }},
    {% endfor %}
    {{ var('prccsr_version') }} as prccsr_version,
    '{{ var('tuva_last_run')}}' as tuva_last_run
from dedupe_records
group by encounter_id, patient_id, prccsr_version, tuva_last_run