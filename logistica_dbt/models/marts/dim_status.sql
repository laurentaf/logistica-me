{{ config(materialized='table') }}

WITH distinct_status AS (
    SELECT DISTINCT
        delivery_status
    FROM {{ ref('stg_shipments') }}
    WHERE delivery_status IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY delivery_status) AS status_id,
        delivery_status,
        CASE 
            WHEN LOWER(delivery_status) = 'delivered' THEN TRUE
            ELSE FALSE
        END AS is_delivered
    FROM distinct_status
)
SELECT * FROM with_id
