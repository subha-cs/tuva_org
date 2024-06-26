{{ config(
    enabled = var('clinical_enabled', False)
) }}


            SELECT
                M.Data_SOURCE
                ,coalesce(M.DISPENSING_DATE,'1900-01-01') AS SOURCE_DATE
                ,'MEDICATION' AS TABLE_NAME
                ,'Medication ID' as DRILL_DOWN_KEY
                ,IFNULL(MEDICATION_ID, 'NULL') AS DRILL_DOWN_VALUE
                -- ,M.CLAIM_TYPE AS CLAIM_TYPE
                ,'MEDICATION_ID' AS FIELD_NAME
                ,case when M.MEDICATION_ID is not null then 'valid' else 'null' end as BUCKET_NAME
                ,null as INVALID_REASON
                ,CAST(MEDICATION_ID AS VARCHAR(255)) AS FIELD_VALUE
            FROM {{ ref('medication') }} M
            