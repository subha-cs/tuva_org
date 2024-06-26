{{ config(
    enabled = var('clinical_enabled', False)
) }}


            SELECT
                M.Data_SOURCE
                ,coalesce(GETDATE(),'1900-01-01') AS SOURCE_DATE
                ,'PATIENT' AS TABLE_NAME
                ,'Patient ID' as DRILL_DOWN_KEY
                ,IFNULL(PATIENT_ID, 'NULL') AS DRILL_DOWN_VALUE
                -- ,M.CLAIM_TYPE AS CLAIM_TYPE
                ,'LATITUDE' AS FIELD_NAME
                ,case when M.LATITUDE is not null then 'valid' else 'null' end as BUCKET_NAME
                ,null as INVALID_REASON
                ,CAST(LATITUDE AS VARCHAR(255)) AS FIELD_VALUE
            FROM {{ ref('patient') }} M
            