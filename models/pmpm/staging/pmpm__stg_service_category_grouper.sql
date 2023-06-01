{{ config(
     enabled = var('pmpm_enabled',var('tuva_marts_enabled',True))
   )
}}


SELECT
  claim_id
, claim_line_number
, service_category_1
, service_category_2
from {{ ref('service_category__service_category_grouper') }}