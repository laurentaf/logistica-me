{{ config(tags=['data_quality']) }}

SELECT *
FROM {{ ref('stg_raw_logs') }}
WHERE event_timestamp IS NOT NULL 
  AND event_timestamp::timestamp IS NULL