{{
  config(
    materialized='table',
    tags=['staging']
  )
}}

WITH raw_logs AS (
  SELECT
    log_id,
    timestamp::timestamp AS event_timestamp,
    ip_address,
    http_method,
    endpoint,
    status_code::integer AS status_code,
    response_time_ms::integer AS response_time_ms,
    user_agent
  FROM {{ ref('raw_logs') }}
)

SELECT * FROM raw_logs