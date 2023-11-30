select
    claim_id
    , data_source
    , column_name
    , normalized_code
    , occurrence_count
    , next_occurrence_count
    , occurrence_row_count
from {{ ref('normalized_input__int_discharge_disposition_voting') }}
where (occurrence_row_count = 1
        and occurrence_count > next_occurrence_count)