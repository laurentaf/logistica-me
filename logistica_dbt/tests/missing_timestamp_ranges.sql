{{ config(tags=['completeness']) }}

WITH hourly_counts AS (
  SELECT 
    DATE_TRUNC('hour', event_timestamp) as hour_start,
    COUNT(*) as request_count
  FROM {{ ref('stg_raw_logs') }}
  GROUP BY DATE_TRUNC('hour', event_timestamp)
)

SELECT *
FROM hourly_counts
WHERE request_count = 0