{{ config(tags=['data_quality']) }}

SELECT *
FROM {{ ref('stg_raw_logs') }}
WHERE ip_address IS NOT NULL 
  AND (
    -- Validate IPv4 format
    (ip_address !~ '^(\d{1,3}\.){3}\d{1,3}$') OR
    -- Validate IPv4 octets (0-255)
    (string_to_array(ip_address, '.')::int[] @> ARRAY[256]) OR
    (string_to_array(ip_address, '.')::int[] @> ARRAY[-1])
  )