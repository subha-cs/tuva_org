{{ config(
    enabled = var('claims_enabled', False)
) }}

SELECT  
    M.Data_SOURCE
    ,coalesce(M.PAID_DATE,'1900-01-01') AS SOURCE_DATE
    ,'PHARMACY_CLAIM' AS TABLE_NAME
    ,'Claim ID | Claim Line Number' AS DRILL_DOWN_KEY
    ,IFNULL(M.CLAIM_ID, 'NULL') || '|' || IFNULL(TO_VARCHAR(M.CLAIM_LINE_NUMBER), 'NULL')  AS DRILL_DOWN_VALUE
    ,'PHARMACY' AS CLAIM_TYPE
    ,'DAYS_SUPPLY' AS FIELD_NAME
    ,CASE 
        WHEN M.DAYS_SUPPLY is null then 'null' else 'valid' END AS BUCKET_NAME
    ,null as INVALID_REASON
    ,CAST(DAYS_SUPPLY AS VARCHAR(255)) AS FIELD_VALUE
FROM {{ ref('intelligence__stg_pharmacy_claim') }} M