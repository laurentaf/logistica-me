{{ config(tags=['referential_integrity']) }}

SELECT 
  f.log_id
FROM {{ ref('fact_log_events') }} f
LEFT JOIN {{ ref('stg_raw_logs') }} s ON f.log_id = s.log_id
WHERE s.log_id IS NULL