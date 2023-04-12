{{ config(enabled = var('tuva_chronic_conditions_enabled',var('tuva_packages_enabled',True)) ) }}

with condition_columns as
    (select distinct condition, condition_column_name from {{ ref('tuva_chronic_conditions__tuva_chronic_conditions_hierarchy')}})

select
    p.patient_id
    , {{ dbt_utils.pivot(
          column='cc.condition_column_name'
        , values=dbt_utils.get_column_values(ref('tuva_chronic_conditions__tuva_chronic_conditions_hierarchy'), 'condition_column_name','condition_column_name')
        , agg='max'
        , then_value= 1
        , else_value= 0
        , quote_identifiers = False
      ) }}
from {{ var('patient') }} p
left join {{ ref('tuva_chronic_conditions__tuva_chronic_conditions_long') }} l
    on p.patient_id = l.patient_id
left join condition_columns cc
    on l.condition = cc.condition
group by
    p.patient_id