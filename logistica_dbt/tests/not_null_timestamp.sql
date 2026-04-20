{{
  config(
    tags=['not_null']
  )
}}

SELECT *
FROM {{ ref('fact_log_events') }}
WHERE event_timestamp IS NULL