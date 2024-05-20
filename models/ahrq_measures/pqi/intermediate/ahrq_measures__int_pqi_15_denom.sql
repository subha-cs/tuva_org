{{ config(
    enabled = var('pqi_enabled', var('claims_enabled', var('tuva_marts_enabled', False))) | as_bool
) }}

select distinct
    cast(left(e.year_month, 4) as int) as year_number
  , e.patient_id
  , e.data_source
  , {{ datediff('p.birth_date', 'e.first_day_of_month', 'year') }} as age
  , '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ ref('ahrq_measures__stg_pqi_member_months') }} as e
inner join {{ ref('ahrq_measures__stg_pqi_patient') }} as p 
  on e.patient_id = p.patient_id
  and p.data_source = e.data_source
where 
  {{ datediff('p.birth_date', 'e.first_day_of_month', 'year') }} >= 18
  and
  {{ datediff('p.birth_date', 'e.first_day_of_month', 'year') }} <= 39
