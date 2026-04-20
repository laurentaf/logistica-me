{{ config(tags=['data_consistency']) }}

SELECT *
FROM {{ ref('stg_raw_logs') }}
WHERE status_code = 200 AND response_time_ms > 5000  -- Successful but slow responses