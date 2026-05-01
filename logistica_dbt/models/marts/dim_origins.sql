{{ config(materialized='table') }}

WITH distinct_origins AS (
    SELECT DISTINCT
        origin
    FROM {{ ref('stg_shipments') }}
    WHERE origin IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY origin) AS origin_id,
        origin AS origin_name
    FROM distinct_origins
)
SELECT * FROM with_id
