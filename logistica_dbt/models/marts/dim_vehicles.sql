{{ config(materialized='table') }}

WITH distinct_vehicles AS (
    SELECT DISTINCT
        vehicle_type
    FROM {{ ref('stg_shipments') }}
    WHERE vehicle_type IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY vehicle_type) AS vehicle_id,
        vehicle_type
    FROM distinct_vehicles
)
SELECT * FROM with_id
