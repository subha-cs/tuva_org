{{ config(
     enabled = var('readmissions_enabled',var('tuva_marts_enabled',True))
   )
}}

select
  encounter_id
, normalized_code
, normalized_code_type
, '{{ var('tuva_last_run')}}' as tuva_last_run
from {{ ref('core__procedure') }}

