{{ config(materialized='table', tags=['staging']) }}

SELECT
  shipment_id,
  timestamp::timestamp AS event_timestamp,
  origin,
  destination,
  weight_kg::numeric AS weight_kg,
  delivery_status,
  vehicle_type,
  estimated_delay_minutes::integer AS estimated_delay_minutes
FROM (
  {{ union_shipment_seeds() }}
) AS all_shipments
