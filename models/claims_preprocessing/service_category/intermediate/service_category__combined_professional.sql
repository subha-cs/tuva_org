{{ config(
     enabled = var('claims_preprocessing_enabled',var('claims_enabled',var('tuva_marts_enabled',False)))
   )
}}

select *
from {{ ref('service_category__acute_inpatient_professional') }}

union all

select *
from {{ ref('service_category__ambulance_professional') }}

union all

select *
from {{ ref('service_category__ambulatory_surgery_professional') }}

union all

select *
from {{ ref('service_category__dialysis_professional') }}

union all

select *
from {{ ref('service_category__dme_professional') }}

union all

select *
from {{ ref('service_category__emergency_department_professional') }}

union all

select *
from {{ ref('service_category__home_health_professional') }}

union all

select *
from {{ ref('service_category__hospice_professional') }}

union all

select *
from {{ ref('service_category__inpatient_psychiatric_professional') }}

union all

select *
from {{ ref('service_category__inpatient_rehab_professional') }}

union all

select *
from {{ ref('service_category__lab_professional') }}

union all

select *
from {{ ref('service_category__office_visit_professional') }}

union all

select *
from {{ ref('service_category__outpatient_hospital_or_clinic_professional') }}

union all

select *
from {{ ref('service_category__outpatient_psychiatric_professional') }}

union all

select *
from {{ ref('service_category__outpatient_rehab_professional') }}

union all

select *
from {{ ref('service_category__skilled_nursing_professional') }}

union all

select *
from {{ ref('service_category__urgent_care_professional') }}
