{{ config(tags=['statistical', 'accuracy']) }}

WITH response_time_stats AS (
  SELECT 
    AVG(response_time_ms) as mean,
    STDDEV(response_time_ms) as stddev,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY response_time_ms) as q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY response_time_ms) as q3,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY response_time_ms) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY response_time_ms) as iqr
  FROM {{ ref('stg_raw_logs') }}
  WHERE response_time_ms IS NOT NULL
),

outliers AS (
  SELECT 
    s.*,
    CASE 
      WHEN s.response_time_ms > r.mean + (3 * r.stddev) THEN 'extreme_high'
      WHEN s.response_time_ms < r.mean - (3 * r.stddev) THEN 'extreme_low'
      WHEN s.response_time_ms > r.q3 + (1.5 * r.iqr) THEN 'high_outlier'
      WHEN s.response_time_ms < r.q1 - (1.5 * r.iqr) THEN 'low_outlier'
    END as outlier_type
  FROM {{ ref('stg_raw_logs') }} s
  CROSS JOIN response_time_stats r
  WHERE s.response_time_ms IS NOT NULL
    AND (
      s.response_time_ms > r.mean + (3 * r.stddev) OR
      s.response_time_ms < r.mean - (3 * r.stddev) OR
      s.response_time_ms > r.q3 + (1.5 * r.iqr) OR
      s.response_time_ms < r.q1 - (1.5 * r.iqr)
    )
)

SELECT *
FROM outliers