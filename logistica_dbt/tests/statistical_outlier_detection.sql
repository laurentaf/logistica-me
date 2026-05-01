{{ config(tags=['statistical', 'accuracy']) }}

WITH weight_stats AS (
  SELECT 
    AVG(weight_kg) as mean_weight,
    STDDEV(weight_kg) as stddev_weight,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight_kg) as q1_weight,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight_kg) as q3_weight,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight_kg) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight_kg) as iqr_weight
  FROM {{ ref('stg_shipments') }}
  WHERE weight_kg IS NOT NULL
),
delay_stats AS (
  SELECT 
    AVG(estimated_delay_minutes) as mean_delay,
    STDDEV(estimated_delay_minutes) as stddev_delay,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY estimated_delay_minutes) as q1_delay,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY estimated_delay_minutes) as q3_delay,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY estimated_delay_minutes) - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY estimated_delay_minutes) as iqr_delay
  FROM {{ ref('stg_shipments') }}
  WHERE estimated_delay_minutes IS NOT NULL
),
weight_outliers AS (
  SELECT 
    s.shipment_id,
    s.weight_kg,
    'weight' as metric,
    CASE 
      WHEN s.weight_kg > w.mean_weight + (3 * w.stddev_weight) THEN 'extreme_high'
      WHEN s.weight_kg < w.mean_weight - (3 * w.stddev_weight) THEN 'extreme_low'
      WHEN s.weight_kg > w.q3_weight + (1.5 * w.iqr_weight) THEN 'high_outlier'
      WHEN s.weight_kg < w.q1_weight - (1.5 * w.iqr_weight) THEN 'low_outlier'
    END as outlier_type
  FROM {{ ref('stg_shipments') }} s
  CROSS JOIN weight_stats w
  WHERE s.weight_kg IS NOT NULL
    AND (
      s.weight_kg > w.mean_weight + (3 * w.stddev_weight) OR
      s.weight_kg < w.mean_weight - (3 * w.stddev_weight) OR
      s.weight_kg > w.q3_weight + (1.5 * w.iqr_weight) OR
      s.weight_kg < w.q1_weight - (1.5 * w.iqr_weight)
    )
),
delay_outliers AS (
  SELECT 
    s.shipment_id,
    s.estimated_delay_minutes as value,
    'delay_minutes' as metric,
    CASE 
      WHEN s.estimated_delay_minutes > d.mean_delay + (3 * d.stddev_delay) THEN 'extreme_high'
      WHEN s.estimated_delay_minutes < d.mean_delay - (3 * d.stddev_delay) THEN 'extreme_low'
      WHEN s.estimated_delay_minutes > d.q3_delay + (1.5 * d.iqr_delay) THEN 'high_outlier'
      WHEN s.estimated_delay_minutes < d.q1_delay - (1.5 * d.iqr_delay) THEN 'low_outlier'
    END as outlier_type
  FROM {{ ref('stg_shipments') }} s
  CROSS JOIN delay_stats d
  WHERE s.estimated_delay_minutes IS NOT NULL
    AND (
      s.estimated_delay_minutes > d.mean_delay + (3 * d.stddev_delay) OR
      s.estimated_delay_minutes < d.mean_delay - (3 * d.stddev_delay) OR
      s.estimated_delay_minutes > d.q3_delay + (1.5 * d.iqr_delay) OR
      s.estimated_delay_minutes < d.q1_delay - (1.5 * d.iqr_delay)
    )
)

SELECT * FROM weight_outliers
UNION ALL
SELECT * FROM delay_outliers
