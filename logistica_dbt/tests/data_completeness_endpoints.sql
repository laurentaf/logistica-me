{{ config(tags=['completeness']) }}

SELECT 
  endpoint,
  COUNT(*) as record_count
FROM {{ ref('stg_raw_logs') }}
GROUP BY endpoint
HAVING COUNT(*) < 5  -- Threshold for low-volume endpoints