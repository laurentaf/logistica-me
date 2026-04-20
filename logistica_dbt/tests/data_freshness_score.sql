{{ config(tags=['timeliness', 'scoring']) }}

WITH latest_timestamp AS (
  SELECT MAX(event_timestamp) as latest_ts
  FROM {{ ref('stg_raw_logs') }}
),

freshness_metrics AS (
  SELECT 
    CURRENT_TIMESTAMP as current_time,
    l.latest_ts,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - l.latest_ts)) / 3600 as hours_since_latest,
    COUNT(*) as total_records,
    COUNT(DISTINCT DATE(event_timestamp)) as unique_days
  FROM {{ ref('stg_raw_logs') }}
  CROSS JOIN latest_timestamp l
)

SELECT 
  current_time,
  latest_ts,
  hours_since_latest,
  total_records,
  unique_days,
  CASE 
    WHEN hours_since_latest <= 24 THEN 'EXCELLENT'
    WHEN hours_since_latest <= 72 THEN 'GOOD'
    WHEN hours_since_latest <= 168 THEN 'FAIR'
    ELSE 'POOR'
  END as freshness_score
FROM freshness_metrics