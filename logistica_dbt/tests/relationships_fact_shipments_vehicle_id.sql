{{ config(tags=['relationships', 'integrity']) }}

WITH child AS (
    SELECT vehicle_id AS from_field
    FROM {{ ref('fact_shipments') }}
    WHERE vehicle_id IS NOT NULL
),

parent AS (
    SELECT vehicle_id AS to_field
    FROM {{ ref('dim_vehicles') }}
)

SELECT
    from_field
FROM child
LEFT JOIN parent ON child.from_field = parent.to_field
WHERE parent.to_field IS NULL