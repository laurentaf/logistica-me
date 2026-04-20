{{
  config(
    materialized='table',
    tags=['marts', 'dimension']
  )
}}

WITH endpoints AS (
  SELECT
    DISTINCT endpoint,
    COUNT(*) AS total_requests,
    AVG(response_time_ms) AS avg_response_time,
    MIN(response_time_ms) AS min_response_time,
    MAX(response_time_ms) AS max_response_time,
    SUM(CASE WHEN status_code >= 200 AND status_code < 300 THEN 1 ELSE 0 END) AS success_count,
    SUM(CASE WHEN status_code >= 400 AND status_code < 500 THEN 1 ELSE 0 END) AS client_error_count,
    SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS server_error_count
  FROM {{ ref('stg_raw_logs') }}
  GROUP BY 1
)

SELECT
  endpoint,
  total_requests,
  avg_response_time,
  min_response_time,
  max_response_time,
  success_count,
  client_error_count,
  server_error_count,
  ROUND((success_count::decimal / total_requests) * 100, 2) AS success_rate_pct,
  ROUND((client_error_count::decimal / total_requests) * 100, 2) AS client_error_rate_pct,
  ROUND((server_error_count::decimal / total_requests) * 100, 2) AS server_error_rate_pct
FROM endpoints
ORDER BY total_requests DESC