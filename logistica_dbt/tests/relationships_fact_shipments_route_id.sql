{{ config(tags=['relationships', 'integrity']) }}

WITH child AS (
    SELECT route_id AS from_field
    FROM {{ ref('fact_shipments') }}
    WHERE route_id IS NOT NULL
),

parent AS (
    SELECT route_id AS to_field
    FROM {{ ref('dim_routes') }}
)

SELECT
    from_field
FROM child
LEFT JOIN parent ON child.from_field = parent.to_field
WHERE parent.to_field IS NULL