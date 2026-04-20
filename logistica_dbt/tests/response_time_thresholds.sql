{{ config(tags=['business_logic']) }}

SELECT *
FROM {{ ref('fact_log_events') }}
WHERE response_time_ms > 10000  -- 10 seconds threshold