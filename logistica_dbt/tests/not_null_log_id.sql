{{
  config(
    tags=['not_null']
  )
}}

SELECT *
FROM {{ ref('fact_log_events') }}
WHERE log_id IS NULL