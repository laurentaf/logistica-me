{{ config(materialized='table', tags=['dimension']) }}

WITH distinct_routes AS (
    SELECT DISTINCT
        s.origin,
        s.destination
    FROM {{ ref('stg_shipments') }} s
    WHERE s.origin IS NOT NULL 
      AND s.destination IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY origin, destination) AS route_id,
        origin,
        destination,
        CONCAT(origin, ' → ', destination) AS route_name
    FROM distinct_routes
)
SELECT * FROM with_id
ORDER BY route_id
