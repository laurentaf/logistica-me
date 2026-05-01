{{ config(materialized='table', tags=['risk', 'marts', 'forecast', 'temporal']) }}

-- Temporal Delay Patterns
-- Analyzes delay patterns by time dimensions: hour of day, day of week, date trends
-- Key drivers: time of day congestion, weekly patterns, seasonal effects

WITH temporal_stats AS (
    SELECT
        f.event_date,
        f.event_hour,
        -- Day of week (0=Sunday, 6=Saturday)
        EXTRACT(DOW FROM f.event_timestamp) AS day_of_week,
        -- Is weekend flag
        CASE WHEN EXTRACT(DOW FROM f.event_timestamp) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
        -- Hour bucket for analysis
        CASE
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 6 AND 10 THEN 'MORNING_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 11 AND 14 THEN 'MIDDAY'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 15 AND 18 THEN 'AFTERNOON_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 19 AND 22 THEN 'EVENING'
            ELSE 'NIGHT'
        END AS time_of_day_bucket,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE f.is_delayed = TRUE) AS delayed_shipments,
        AVG(f.estimated_delay_minutes) AS avg_delay_minutes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS median_delay_minutes,
        MAX(f.estimated_delay_minutes) AS max_delay_minutes,
        STDDEV(f.estimated_delay_minutes) AS stddev_delay_minutes,
        -- Percent delayed
        ROUND(
            COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS pct_delayed,
        -- Weight distribution
        AVG(f.weight_kg) AS avg_weight_kg,
        COUNT(*) FILTER (WHERE f.weight_kg > 1000) AS heavy_shipments_count,
        -- Vehicle type distribution (most common)
        MODE() WITHIN GROUP (ORDER BY v.vehicle_type) AS most_common_vehicle_type
    FROM {{ ref('fact_shipments') }} f
    LEFT JOIN {{ ref('dim_vehicles') }} v ON f.vehicle_id = v.vehicle_id
    GROUP BY
        f.event_date,
        f.event_hour,
        EXTRACT(DOW FROM f.event_timestamp),
        CASE WHEN EXTRACT(DOW FROM f.event_timestamp) IN (0, 6) THEN TRUE ELSE FALSE END,
        CASE
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 6 AND 10 THEN 'MORNING_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 11 AND 14 THEN 'MIDDAY'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 15 AND 18 THEN 'AFTERNOON_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 19 AND 22 THEN 'EVENING'
            ELSE 'NIGHT'
        END
    ORDER BY event_date DESC, event_hour
)

SELECT
    event_date,
    event_hour,
    day_of_week,
    is_weekend,
    time_of_day_bucket,
    total_shipments,
    delayed_shipments,
    ROUND(avg_delay_minutes, 2) AS avg_delay_minutes,
    ROUND(median_delay_minutes, 2) AS median_delay_minutes,
    max_delay_minutes,
    ROUND(stddev_delay_minutes, 2) AS stddev_delay_minutes,
    pct_delayed,
    ROUND(avg_weight_kg, 2) AS avg_weight_kg,
    heavy_shipments_count,
    most_common_vehicle_type
FROM temporal_stats
ORDER BY event_date DESC, event_hour
