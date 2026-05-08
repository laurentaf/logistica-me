{{ config(tags=['relationships', 'integrity']) }}

WITH child AS (
    SELECT incident_id AS from_field
    FROM {{ ref('fact_shipments') }}
    WHERE incident_id IS NOT NULL
),

parent AS (
    SELECT incident_id AS to_field
    FROM {{ ref('dim_incidents') }}
)

SELECT
    from_field
FROM child
LEFT JOIN parent ON child.from_field = parent.to_field
WHERE parent.to_field IS NULL