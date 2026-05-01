{{ config(materialized='table', tags=['marts', 'fact']) }}

WITH shipments_with_keys AS (
    SELECT
        s.shipment_id,
        s.event_timestamp,
        s.weight_kg,
        s.estimated_delay_minutes,
        r.route_id,
        v.vehicle_id,
        i.incident_id,
        -- Derived metrics
        CASE WHEN s.estimated_delay_minutes <= 0 THEN TRUE ELSE FALSE END AS is_on_time,
        CASE WHEN s.estimated_delay_minutes > 0 THEN TRUE ELSE FALSE END AS is_delayed,
        DATE_TRUNC('day', s.event_timestamp) AS event_date,
        DATE_TRUNC('hour', s.event_timestamp) AS event_hour
    FROM {{ ref('stg_shipments') }} s
    LEFT JOIN {{ ref('dim_routes') }} r 
        ON r.origin = s.origin 
        AND r.destination = s.destination
    LEFT JOIN {{ ref('dim_vehicles') }} v 
        ON v.vehicle_type = s.vehicle_type
    LEFT JOIN {{ ref('dim_incidents') }} i 
        ON i.delivery_status = s.delivery_status
        AND i.delay_category = CASE
            WHEN s.estimated_delay_minutes <= 0 THEN 'ON_TIME'
            WHEN s.estimated_delay_minutes <= 30 THEN 'MINOR_DELAY'
            WHEN s.estimated_delay_minutes <= 60 THEN 'MODERATE_DELAY'
            ELSE 'MAJOR_DELAY'
        END
)

SELECT
    shipment_id,
    event_timestamp,
    route_id,
    vehicle_id,
    incident_id,
    weight_kg,
    estimated_delay_minutes,
    is_on_time,
    is_delayed,
    event_date,
    event_hour
FROM shipments_with_keys
