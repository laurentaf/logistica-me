{{ config(tags=['completeness', 'statistical']) }}

WITH column_null_counts AS (
  SELECT 
    'log_id' as column_name,
    COUNT(CASE WHEN log_id IS NULL THEN 1 END) as null_count,
    COUNT(*) as total_count
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'event_timestamp',
    COUNT(CASE WHEN event_timestamp IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'ip_address',
    COUNT(CASE WHEN ip_address IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'http_method',
    COUNT(CASE WHEN http_method IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'endpoint',
    COUNT(CASE WHEN endpoint IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'status_code',
    COUNT(CASE WHEN status_code IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'response_time_ms',
    COUNT(CASE WHEN response_time_ms IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
  
  UNION ALL
  
  SELECT 
    'user_agent',
    COUNT(CASE WHEN user_agent IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_raw_logs') }}
)

SELECT 
  column_name,
  null_count,
  total_count,
  ROUND((null_count::float / total_count) * 100, 2) as null_percentage,
  CASE 
    WHEN (null_count::float / total_count) > 0.05 THEN 'FAIL'  -- >5% null rate
    ELSE 'PASS'
  END as test_status
FROM column_null_counts