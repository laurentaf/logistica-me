{{ config(materialized='table', tags=['marts', 'fact']) }}

WITH shipments_with_keys AS (
    SELECT
        s.shipment_id,
        s.event_timestamp,
        s.weight_kg,
        s.estimated_delay_minutes,
        o.origin_id,
        d.destination_id,
        v.vehicle_id,
        st.status_id
    FROM {{ ref('stg_shipments') }} s
    LEFT JOIN {{ ref('dim_origins') }} o ON o.origin_name = s.origin
    LEFT JOIN {{ ref('dim_destinations') }} d ON d.destination_name = s.destination
    LEFT JOIN {{ ref('dim_vehicles') }} v ON v.vehicle_type = s.vehicle_type
    LEFT JOIN {{ ref('dim_status') }} st ON st.delivery_status = s.delivery_status
)

SELECT
    shipment_id,
    event_timestamp,
    origin_id,
    destination_id,
    vehicle_id,
    status_id,
    weight_kg,
    estimated_delay_minutes,
    DATE_TRUNC('day', event_timestamp) AS event_date,
    DATE_TRUNC('hour', event_timestamp) AS event_hour
FROM shipments_with_keys
