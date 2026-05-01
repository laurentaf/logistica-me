{{ config(tags=['uniqueness', 'cross_file']) }}

WITH all_shipments AS (
  SELECT shipment_id, COUNT(*) as file_count
  FROM {{ ref('stg_shipments') }}
  GROUP BY shipment_id
)

SELECT 
  shipment_id,
  file_count
FROM all_shipments
WHERE file_count > 1