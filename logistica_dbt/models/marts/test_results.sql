{{
  config(
    materialized='table',
    tags=['test_results']
  )
}}

WITH test_executions AS (
  SELECT 
    'data_quality' as test_category,
    'valid_ip_address' as test_name,
    COUNT(*) as failures,
    'IP address format validation' as description
  FROM {{ ref('valid_ip_address') }}
  
  UNION ALL
  
  SELECT 
    'data_quality',
    'valid_timestamp_format',
    COUNT(*),
    'Timestamp format validation'
  FROM {{ ref('valid_timestamp_format') }}
  
  UNION ALL
  
  SELECT 
    'referential_integrity',
    'foreign_key_integrity',
    COUNT(*),
    'Foreign key relationship validation'
  FROM {{ ref('foreign_key_integrity') }}
  
  UNION ALL
  
  SELECT 
    'business_logic',
    'response_time_thresholds',
    COUNT(*),
    'Response time SLA violations'
  FROM {{ ref('response_time_thresholds') }}
  
  UNION ALL
  
  SELECT 
    'completeness',
    'data_completeness_endpoints',
    COUNT(*),
    'Low-volume endpoint detection'
  FROM {{ ref('data_completeness_endpoints') }}
  
  UNION ALL
  
  SELECT 
    'data_consistency',
    'consistency_status_response_time',
    COUNT(*),
    'Status code vs response time consistency'
  FROM {{ ref('consistency_status_response_time') }}
  
  UNION ALL
  
  SELECT 
    'data_quality',
    'endpoint_pattern_consistency',
    COUNT(*),
    'Endpoint path format validation'
  FROM {{ ref('endpoint_pattern_consistency') }}
  
  UNION ALL
  
  SELECT 
    'data_quality',
    'user_agent_format',
    COUNT(*),
    'User agent format validation'
  FROM {{ ref('user_agent_format') }}
)

SELECT 
  test_category,
  test_name,
  failures,
  description,
  CASE 
    WHEN failures = 0 THEN 'PASS'
    ELSE 'FAIL'
  END as test_status,
  CURRENT_TIMESTAMP as execution_timestamp
FROM test_executions
ORDER BY test_category, test_name