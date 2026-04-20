{{
  config(
    tags=['accepted_values']
  )
}}

SELECT *
FROM {{ ref('fact_log_events') }}
WHERE response_time_ms < 0