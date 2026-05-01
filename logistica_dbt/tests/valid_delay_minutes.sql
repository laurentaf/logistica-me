{{ config(tags=['data_quality']) }}

-- Validates that estimated_delay_minutes is not null (optional: could check integer type as well)
SELECT *
FROM {{ ref('stg_shipments') }}
WHERE estimated_delay_minutes IS NULL
