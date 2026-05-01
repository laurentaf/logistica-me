{{ config(materialized='table', tags=['dimension']) }}

WITH incident_sources AS (
    SELECT DISTINCT
        delivery_status,
        estimated_delay_minutes,
        CASE
            WHEN estimated_delay_minutes <= 0 THEN 'ON_TIME'
            WHEN estimated_delay_minutes <= 30 THEN 'MINOR_DELAY'
            WHEN estimated_delay_minutes <= 60 THEN 'MODERATE_DELAY'
            ELSE 'MAJOR_DELAY'
        END AS delay_category,
        CASE WHEN estimated_delay_minutes <= 0 THEN TRUE ELSE FALSE END AS is_on_time,
        CASE WHEN estimated_delay_minutes > 0 THEN TRUE ELSE FALSE END AS is_delayed
    FROM {{ ref('stg_shipments') }}
    WHERE delivery_status IS NOT NULL
),
with_id AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY delivery_status,
                CASE delay_category
                    WHEN 'ON_TIME' THEN 0
                    WHEN 'MINOR_DELAY' THEN 1
                    WHEN 'MODERATE_DELAY' THEN 2
                    ELSE 3
                END
        ) AS incident_id,
        delivery_status,
        delay_category,
        is_on_time,
        is_delayed,
        CONCAT(delivery_status, ' - ', delay_category) AS incident_type
    FROM incident_sources
)
SELECT 
    incident_id,
    delivery_status,
    delay_category,
    is_on_time,
    is_delayed,
    incident_type
FROM with_id
ORDER BY incident_id
