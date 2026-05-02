{{ config(materialized='table') }}

WITH base_shipments AS (
    SELECT * FROM {{ ref('shipments_00001') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00002') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00003') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00004') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00005') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00006') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00007') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00008') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00009') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00010') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00011') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00012') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00013') }}
    UNION ALL
    SELECT * FROM {{ ref('shipments_00014') }}
)
SELECT * FROM base_shipments
