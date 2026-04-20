{{ config(tags=['uniqueness', 'cross_file']) }}

WITH all_logs AS (
  SELECT log_id, COUNT(*) as file_count
  FROM {{ ref('stg_raw_logs') }}
  GROUP BY log_id
)

SELECT 
  log_id,
  file_count
FROM all_logs
WHERE file_count > 1