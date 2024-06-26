{{ config(
    enabled = var('claims_enabled', False)
) }}

SELECT DISTINCT
    M.Data_SOURCE
    ,coalesce(M.ENROLLMENT_START_DATE,'1900-01-01') AS SOURCE_DATE
    ,'ELIGIBILITY' AS TABLE_NAME
    ,'Member ID' AS DRILL_DOWN_KEY
    ,IFNULL(M.MEMBER_ID,'NULL') AS DRILL_DOWN_VALUE
    ,'ELIGIBILITY' AS CLAIM_TYPE
    ,'ENROLLMENT_END_DATE' AS FIELD_NAME
    ,CASE 
    
        WHEN M.ENROLLMENT_END_DATE > CURRENT_DATE() THEN 'invalid'
        WHEN M.ENROLLMENT_END_DATE <= '1901-01-01' THEN 'invalid'
        WHEN M.ENROLLMENT_END_DATE < M.ENROLLMENT_START_DATE THEN 'invalid'
        WHEN M.ENROLLMENT_END_DATE IS NULL THEN 'null'
        ELSE 'valid' 
    END AS BUCKET_NAME
    ,CASE 
    
        WHEN M.ENROLLMENT_END_DATE > CURRENT_DATE() THEN 'future'
        WHEN M.ENROLLMENT_END_DATE <= '1901-01-01' THEN 'too old'
        WHEN M.ENROLLMENT_END_DATE < M.ENROLLMENT_START_DATE THEN 'end date before start date'
        else null
    END AS INVALID_REASON
    ,CAST(ENROLLMENT_END_DATE AS VARCHAR(255)) AS FIELD_VALUE
FROM {{ ref('intelligence__stg_eligibility') }} M