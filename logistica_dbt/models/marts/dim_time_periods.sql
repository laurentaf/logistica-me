{{
  config(
    materialized='table',
    tags=['marts', 'dimension']
  )
}}

WITH time_periods AS (
  SELECT
    DATE_TRUNC('hour', event_timestamp) AS period_start,
    COUNT(*) AS request_count,
    AVG(response_time_ms) AS avg_response_time,
    SUM(CASE WHEN status_code >= 200 AND status_code < 300 THEN 1 ELSE 0 END) AS success_count,
    SUM(CASE WHEN status_code >= 400 AND status_code < 500 THEN 1 ELSE 0 END) AS client_error_count,
    SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS server_error_count
  FROM {{ ref('stg_raw_logs') }}
  GROUP BY 1
)

SELECT
  period_start,
  request_count,
  avg_response_time,
  success_count,
  client_error_count,
  server_error_count,
  ROUND((success_count::decimal / request_count) * 100, 2) AS success_rate_pct
FROM time_periods
ORDER BY period_start