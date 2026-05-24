{{ config(tags=['data_quality']) }}

SELECT *
FROM {{ ref('shipments') }}
WHERE timestamp IS NULL