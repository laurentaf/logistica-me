{{ config(materialized='table') }}

WITH distinct_destinations AS (
    SELECT DISTINCT
        destination
    FROM {{ ref('stg_shipments') }}
    WHERE destination IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY destination) AS destination_id,
        destination AS destination_name
    FROM distinct_destinations
)
SELECT * FROM with_id
