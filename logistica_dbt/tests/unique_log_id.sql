{{
  config(
    tags=['unique']
  )
}}

SELECT 
  log_id,
  COUNT(*) as count
FROM {{ ref('fact_log_events') }}
GROUP BY 1
HAVING count > 1