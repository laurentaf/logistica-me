{{ config(materialized='table', tags=['risk', 'marts', 'forecast']) }}

-- Risk Analysis by Vehicle Type
-- Identifies which vehicle types are associated with higher delays
-- Key drivers: vehicle capacity, speed, infrastructure limitations

WITH vehicle_stats AS (
    SELECT
        f.vehicle_id,
        v.vehicle_type,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE f.is_delayed = TRUE) AS delayed_shipments,
        COUNT(*) FILTER (WHERE f.is_on_time = TRUE) AS on_time_shipments,
        AVG(f.estimated_delay_minutes) AS avg_delay_minutes,
        MEDIAN(f.estimated_delay_minutes) AS median_delay_minutes,
        MAX(f.estimated_delay_minutes) AS max_delay_minutes,
        STDDEV(f.estimated_delay_minutes) AS stddev_delay_minutes,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q1_delay,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q3_delay,
        -- Percent delayed
        ROUND(
            COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS pct_delayed,
        -- Risk score: combination of avg delay and % delayed
        ROUND(
            (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
            (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50),
            2
        ) AS risk_score,
        -- Risk category
        CASE
            WHEN (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
                 (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50) >= 70 THEN 'HIGH'
            WHEN (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
                 (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50) >= 40 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_category,
        -- Weight analysis by vehicle type
        AVG(f.weight_kg) AS avg_weight_kg,
        MEDIAN(f.weight_kg) AS median_weight_kg,
        COUNT(*) FILTER (WHERE f.weight_kg > 1000) AS heavy_shipments_count,
        ROUND(
            COUNT(*) FILTER (WHERE f.weight_kg > 1000)::NUMERIC / COUNT(*) * 100,
            2
        ) AS pct_heavy_shipments,
        -- Time patterns: average delay by hour of day
        DATE_PART('hour', f.event_timestamp) AS avg_event_hour
    FROM {{ ref('fact_shipments') }} f
    LEFT JOIN {{ ref('dim_vehicles') }} v ON f.vehicle_id = v.vehicle_id
    GROUP BY
        f.vehicle_id,
        v.vehicle_type
    ORDER BY risk_score DESC, total_shipments DESC
)

SELECT
    vehicle_id,
    vehicle_type,
    total_shipments,
    delayed_shipments,
    on_time_shipments,
    ROUND(avg_delay_minutes, 2) AS avg_delay_minutes,
    ROUND(median_delay_minutes, 2) AS median_delay_minutes,
    max_delay_minutes,
    ROUND(stddev_delay_minutes, 2) AS stddev_delay_minutes,
    q1_delay,
    q3_delay,
    pct_delayed,
    ROUND(risk_score, 2) AS risk_score,
    risk_category,
    ROUND(avg_weight_kg, 2) AS avg_weight_kg,
    ROUND(median_weight_kg, 2) AS median_weight_kg,
    heavy_shipments_count,
    pct_heavy_shipments,
    ROUND(avg_event_hour, 2) AS avg_event_hour
FROM vehicle_stats
