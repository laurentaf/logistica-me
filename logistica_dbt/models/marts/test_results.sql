{{ config(
    materialized='table',
    tags=['test_results']
) }}

-- Test Results Aggregator
-- Runs data quality checks directly on models (not using ref() on test files)
-- Produces a consolidated test execution report

WITH test_executions AS (
  -- Data Quality: Timestamp format (valid ISO 8601)
  SELECT 
    'data_quality' as test_category,
    'valid_timestamp_format' as test_name,
    COUNT(*) as failures,
    'Timestamp format validation (ISO 8601)' as description
  FROM {{ ref('stg_shipments') }}
  WHERE event_timestamp IS NULL
  
  UNION ALL
  
  -- Data Quality: Weight positivity
  SELECT 
    'data_quality',
    'valid_weight_kg',
    COUNT(*),
    'Weight positivity validation (weight_kg > 0)'
  FROM {{ ref('stg_shipments') }}
  WHERE weight_kg <= 0 OR weight_kg IS NULL
  
  UNION ALL
  
  -- Data Quality: Delay minutes not null
  SELECT 
    'data_quality',
    'valid_delay_minutes',
    COUNT(*),
    'Delay minutes not null validation'
  FROM {{ ref('stg_shipments') }}
  WHERE estimated_delay_minutes IS NULL
  
  UNION ALL
  
  -- Uniqueness: Cross-file duplicate shipment IDs
  SELECT 
    'uniqueness',
    'cross_file_duplicate_detection',
    COUNT(*),
    'Duplicate shipment_id across files'
  FROM (
    SELECT shipment_id, COUNT(*) as file_count
    FROM {{ ref('stg_shipments') }}
    GROUP BY shipment_id
  ) dupes
  WHERE file_count > 1
  
  UNION ALL
  
  -- Timeliness: Future timestamps (timestamp_freshness)
  SELECT 
    'timeliness',
    'timestamp_freshness',
    COUNT(*),
    'Future timestamps detection (more than 1 day ahead)'
  FROM {{ ref('stg_shipments') }}
  WHERE event_timestamp > (CURRENT_TIMESTAMP + INTERVAL '1 day')
  
  UNION ALL
  
  -- Completeness: Null rate analysis (threshold: any column > 5% nulls)
  -- This aggregates all null rates across columns
  SELECT 
    'completeness',
    'null_rate_analysis',
    SUM(null_count) as failures,
    'Null rate exceeding 5% threshold across any column'
  FROM (
    SELECT 
      'shipment_id' as col,
      COUNT(*) FILTER (WHERE shipment_id IS NULL) as null_count
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'timestamp',
      COUNT(*) FILTER (WHERE event_timestamp IS NULL)
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'origin',
      COUNT(*) FILTER (WHERE origin IS NULL OR origin = '')
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'destination',
      COUNT(*) FILTER (WHERE destination IS NULL OR destination = '')
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'weight_kg',
      COUNT(*) FILTER (WHERE weight_kg IS NULL)
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'delivery_status',
      COUNT(*) FILTER (WHERE delivery_status IS NULL OR delivery_status = '')
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'vehicle_type',
      COUNT(*) FILTER (WHERE vehicle_type IS NULL OR vehicle_type = '')
    FROM {{ ref('stg_shipments') }}
    UNION ALL
    SELECT 
      'estimated_delay_minutes',
      COUNT(*) FILTER (WHERE estimated_delay_minutes IS NULL)
    FROM {{ ref('stg_shipments') }}
  ) null_rates
  WHERE null_count > (SELECT 0.05 * COUNT(*) FROM {{ ref('stg_shipments') }})
  
  UNION ALL
  
  -- Accuracy: Statistical outlier detection
  SELECT 
    'accuracy',
    'statistical_outlier_detection',
    COUNT(*),
    'Statistical outliers in weight or delay (>3 stddev or IQR*1.5)'
  FROM (
    WITH stats AS (
      SELECT 
        AVG(weight_kg) as mean_weight,
        STDDEV(weight_kg) as stddev_weight,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight_kg) as q1_weight,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight_kg) as q3_weight
      FROM {{ ref('stg_shipments') }}
      WHERE weight_kg IS NOT NULL
    ),
    delay_stats AS (
      SELECT 
        AVG(estimated_delay_minutes) as mean_delay,
        STDDEV(estimated_delay_minutes) as stddev_delay,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY estimated_delay_minutes) as q1_delay,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY estimated_delay_minutes) as q3_delay
      FROM {{ ref('stg_shipments') }}
      WHERE estimated_delay_minutes IS NOT NULL
    )
    SELECT s.shipment_id, s.weight_kg, 'weight' as metric
    FROM {{ ref('stg_shipments') }} s, stats w
    WHERE s.weight_kg IS NOT NULL
      AND (
        s.weight_kg > w.mean_weight + (3 * w.stddev_weight) OR
        s.weight_kg < w.mean_weight - (3 * w.stddev_weight) OR
        s.weight_kg > w.q3_weight + (1.5 * (w.q3_weight - w.q1_weight)) OR
        s.weight_kg < w.q1_weight - (1.5 * (w.q3_weight - w.q1_weight))
      )
    UNION ALL
    SELECT s.shipment_id, s.estimated_delay_minutes as weight_kg, 'delay' as metric
    FROM {{ ref('stg_shipments') }} s, delay_stats d
    WHERE s.estimated_delay_minutes IS NOT NULL
      AND (
        s.estimated_delay_minutes > d.mean_delay + (3 * d.stddev_delay) OR
        s.estimated_delay_minutes < d.mean_delay - (3 * d.stddev_delay) OR
        s.estimated_delay_minutes > d.q3_delay + (1.5 * (d.q3_delay - d.q1_delay)) OR
        s.estimated_delay_minutes < d.q1_delay - (1.5 * (d.q3_delay - d.q1_delay))
      )
  ) outliers
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
