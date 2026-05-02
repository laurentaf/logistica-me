{{ config(materialized='table', tags=['risk', 'marts', 'forecast']) }}

-- Risk Analysis by Route
-- Identifies which routes have the highest delay rates and severity
-- Key drivers: route characteristics, origin-destination pairs

WITH route_stats AS (
    SELECT
        f.route_id,
        r.origin,
        r.destination,
        r.route_name,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE f.is_delayed = TRUE) AS delayed_shipments,
        COUNT(*) FILTER (WHERE f.is_on_time = TRUE) AS on_time_shipments,
        AVG(f.estimated_delay_minutes) AS avg_delay_minutes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS median_delay_minutes,
        MAX(f.estimated_delay_minutes) AS max_delay_minutes,
        STDDEV(f.estimated_delay_minutes) AS stddev_delay_minutes,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q1_delay,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q3_delay,
        -- Percent delayed (key metric)
        ROUND(
            COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS pct_delayed,
        -- Risk score: weighted combination of avg delay and % delayed
        -- Score ranges 0-100, higher = riskier
        ROUND(
            (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
            (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50),
            2
        ) AS risk_score,
        -- Risk category based on score
        CASE
            WHEN (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
                 (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50) >= 70 THEN 'HIGH'
            WHEN (LEAST(AVG(f.estimated_delay_minutes)::NUMERIC, 120) / 120 * 50) +
                 (LEAST(COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / COUNT(*) * 100, 100) / 100 * 50) >= 40 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS risk_category,
        -- Additional insights
        MIN(f.event_timestamp) AS first_shipment_date,
        MAX(f.event_timestamp) AS last_shipment_date,
        COUNT(*) FILTER (WHERE f.weight_kg > 1000) AS heavy_shipments_count,
        ROUND(
            COUNT(*) FILTER (WHERE f.weight_kg > 1000)::NUMERIC / COUNT(*) * 100,
            2
        ) AS pct_heavy_shipments
    FROM {{ ref('fact_shipments') }} f
    LEFT JOIN {{ ref('dim_routes') }} r ON f.route_id = r.route_id
    GROUP BY
        f.route_id,
        r.origin,
        r.destination,
        r.route_name
    ORDER BY risk_score DESC, total_shipments DESC
)

SELECT
    route_id,
    origin,
    destination,
    route_name,
    total_shipments,
    delayed_shipments,
    on_time_shipments,
    ROUND(avg_delay_minutes::numeric, 2) AS avg_delay_minutes,
    ROUND(median_delay_minutes::numeric, 2) AS median_delay_minutes,
    max_delay_minutes,
    ROUND(stddev_delay_minutes::numeric, 2) AS stddev_delay_minutes,
    q1_delay,
    q3_delay,
    pct_delayed,
    ROUND(risk_score::numeric, 2) AS risk_score,
    risk_category,
    first_shipment_date,
    last_shipment_date,
    heavy_shipments_count,
    pct_heavy_shipments
FROM route_stats
