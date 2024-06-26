{{ config(
    enabled = var('claims_enabled', False)
) }}

SELECT  
    M.Data_SOURCE
    ,coalesce(M.CLAIM_START_DATE,'1900-01-01') AS SOURCE_DATE
    ,'MEDICAL_CLAIM' AS TABLE_NAME
    ,'Claim ID | Claim Line Number' AS DRILL_DOWN_KEY
    ,IFNULL(M.CLAIM_ID, 'NULL') || '|' || IFNULL(TO_VARCHAR(M.CLAIM_LINE_NUMBER), 'NULL') AS DRILL_DOWN_VALUE
    ,M.CLAIM_TYPE AS CLAIM_TYPE
    ,'SERVICE_UNIT_QUANTITY' AS FIELD_NAME
    ,case when M.SERVICE_UNIT_QUANTITY is null then 'null'
                                    else 'valid' end as BUCKET_NAME
    ,null as INVALID_REASON
    ,CAST(SERVICE_UNIT_QUANTITY AS VARCHAR(255)) AS FIELD_VALUE
FROM {{ ref('intelligence__stg_medical_claim') }} M