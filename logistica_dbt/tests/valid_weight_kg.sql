{{ config(tags=['data_quality']) }}

-- Validates that weight_kg is a positive number (greater than zero)
SELECT *
FROM {{ ref('stg_shipments') }}
WHERE weight_kg IS NOT NULL 
  AND weight_kg <= 0
