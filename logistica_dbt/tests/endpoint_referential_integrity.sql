{{ config(tags=['referential_integrity']) }}

SELECT DISTINCT
  f.endpoint
FROM {{ ref('dim_endpoints') }} f
LEFT JOIN {{ ref('stg_raw_logs') }} s ON f.endpoint = s.endpoint
WHERE s.endpoint IS NULL