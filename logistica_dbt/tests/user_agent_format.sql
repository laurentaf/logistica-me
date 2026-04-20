{{ config(tags=['data_quality']) }}

SELECT *
FROM {{ ref('stg_raw_logs') }}
WHERE user_agent IS NOT NULL 
  AND (user_agent = '' OR LENGTH(user_agent) < 10)