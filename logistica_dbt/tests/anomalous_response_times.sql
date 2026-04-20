{{ config(tags=['business_logic']) }}

WITH response_stats AS (
  SELECT 
    endpoint,
    AVG(response_time_ms) as avg_response_time,
    STDDEV(response_time_ms) as std_response_time
  FROM {{ ref('stg_raw_logs') }}
  GROUP BY endpoint
)

SELECT 
  s.*
FROM {{ ref('stg_raw_logs') }} s
JOIN response_stats r ON s.endpoint = r.endpoint
WHERE s.response_time_ms > r.avg_response_time + (3 * r.std_response_time)