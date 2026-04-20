{{
  config(
    materialized='table',
    tags=['marts', 'fact']
  )
}}

WITH log_events AS (
  SELECT
    log_id,
    event_timestamp,
    ip_address,
    http_method,
    endpoint,
    status_code,
    response_time_ms,
    user_agent,
    DATE_TRUNC('day', event_timestamp) AS event_date,
    DATE_TRUNC('hour', event_timestamp) AS event_hour,
    CASE 
      WHEN status_code >= 200 AND status_code < 300 THEN 'success'
      WHEN status_code >= 400 AND status_code < 500 THEN 'client_error'
      WHEN status_code >= 500 THEN 'server_error'
      ELSE 'other'
    END AS status_category,
    CASE 
      WHEN response_time_ms < 100 THEN 'fast'
      WHEN response_time_ms < 500 THEN 'medium'
      WHEN response_time_ms < 1000 THEN 'slow'
      ELSE 'very_slow'
    END AS response_time_category
  FROM {{ ref('stg_raw_logs') }}
)

SELECT * FROM log_events