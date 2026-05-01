{{ config(
    materialized='table',
    tags=['test_results']
) }}

WITH test_executions AS (
  -- Data Quality: Timestamp format
  SELECT 
    'data_quality' as test_category,
    'valid_timestamp_format' as test_name,
    COUNT(*) as failures,
    'Timestamp format validation' as description
  FROM {{ ref('valid_timestamp_format') }}
  
  UNION ALL
  
  -- Data Quality: Weight positivity
  SELECT 
    'data_quality',
    'valid_weight_kg',
    COUNT(*),
    'Weight positivity validation (kg > 0)'
  FROM {{ ref('valid_weight_kg') }}
  
  UNION ALL
  
  -- Data Quality: Delay minutes not null
  SELECT 
    'data_quality',
    'valid_delay_minutes',
    COUNT(*),
    'Delay minutes not null validation'
  FROM {{ ref('valid_delay_minutes') }}
  
  UNION ALL
  
  -- Uniqueness: Cross-file duplicate shipment IDs
  SELECT 
    'uniqueness',
    'cross_file_duplicate_detection',
    COUNT(*),
    'Duplicate shipment_id across files'
  FROM {{ ref('cross_file_duplicate_detection') }}
  
  UNION ALL
  
  -- Timeliness: Future timestamps
  SELECT 
    'timeliness',
    'timestamp_freshness',
    COUNT(*),
    'Future timestamps detection'
  FROM {{ ref('timestamp_freshness') }}
  
  UNION ALL
  
  -- Completeness: Null rate analysis
  SELECT 
    'completeness',
    'null_rate_analysis',
    COUNT(*),
    'Null rate exceeding 5% threshold'
  FROM {{ ref('null_rate_analysis') }}
  WHERE test_status = 'FAIL'
  
  UNION ALL
  
  -- Accuracy: Statistical outlier detection
  SELECT 
    'accuracy',
    'statistical_outlier_detection',
    COUNT(*),
    'Statistical outliers in weight or delay'
  FROM {{ ref('statistical_outlier_detection') }}
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
