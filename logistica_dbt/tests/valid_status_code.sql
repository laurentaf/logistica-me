{{
  config(
    tags=['accepted_values']
  )
}}

SELECT *
FROM {{ ref('fact_log_events') }}
WHERE status_code NOT BETWEEN 100 AND 599