{{ config(tags=['data_consistency']) }}

SELECT *
FROM {{ ref('stg_raw_logs') }}
WHERE endpoint NOT LIKE '/%' AND endpoint != ''