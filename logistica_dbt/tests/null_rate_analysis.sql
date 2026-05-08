{{ config(tags=['completeness', 'statistical']) }}

WITH column_null_counts AS (
  SELECT 
    'shipment_id' as column_name,
    COUNT(CASE WHEN shipment_id IS NULL THEN 1 END) as null_count,
    COUNT(*) as total_count
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'event_timestamp',
    COUNT(CASE WHEN event_timestamp IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'origin',
    COUNT(CASE WHEN origin IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'destination',
    COUNT(CASE WHEN destination IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'weight_kg',
    COUNT(CASE WHEN weight_kg IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'delivery_status',
    COUNT(CASE WHEN delivery_status IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'vehicle_type',
    COUNT(CASE WHEN vehicle_type IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
  
  UNION ALL
  
  SELECT 
    'estimated_delay_minutes',
    COUNT(CASE WHEN estimated_delay_minutes IS NULL THEN 1 END),
    COUNT(*)
  FROM {{ ref('stg_shipments') }}
)

SELECT 
  column_name,
  null_count,
  total_count,
  ROUND(((null_count::numeric) / NULLIF(total_count, 0)) * 100, 2) as null_percentage,
  CASE
    WHEN total_count = 0 THEN 'PASS'
    WHEN ((null_count::numeric) / NULLIF(total_count, 0)) > 0.05 THEN 'FAIL'
    ELSE 'PASS'
  END as test_status
FROM column_null_counts
