{{ config(tags=['timeliness']) }}

SELECT *
FROM {{ ref('stg_shipments') }}
WHERE event_timestamp > CURRENT_TIMESTAMP + INTERVAL '1 day'  -- Future timestamps beyond tolerance