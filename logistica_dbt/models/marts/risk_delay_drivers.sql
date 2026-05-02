{{ config(materialized='table', tags=['risk', 'marts', 'forecast', 'drivers']) }}

-- Multi-Dimensional Delay Driver Analysis
-- Finds combinations of factors that contribute most to delays
-- Analyzes interactions between route, vehicle type, and time patterns

WITH shipment_enriched AS (
    SELECT
        f.shipment_id,
        f.estimated_delay_minutes,
        f.is_delayed,
        f.weight_kg,
        r.route_id,
        r.route_name,
        v.vehicle_id,
        v.vehicle_type,
        -- Temporal buckets from timestamp
        f.event_date,
        f.event_hour,
        EXTRACT(DOW FROM f.event_timestamp) AS day_of_week,
        CASE WHEN EXTRACT(DOW FROM f.event_timestamp) IN (0, 6) THEN 'WEEKEND' ELSE 'WEEKDAY' END AS weekday_weekend,
        CASE
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 6 AND 10 THEN 'MORNING'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 11 AND 14 THEN 'MIDDAY'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 15 AND 18 THEN 'AFTERNOON'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 19 AND 22 THEN 'EVENING'
            ELSE 'NIGHT'
        END AS time_of_day,
        -- Weight category
        CASE
            WHEN f.weight_kg <= 100 THEN 'LIGHT'
            WHEN f.weight_kg <= 500 THEN 'MEDIUM'
            WHEN f.weight_kg <= 1000 THEN 'HEAVY'
            ELSE 'VERY_HEAVY'
        END AS weight_category,
        i.delay_category
    FROM {{ ref('fact_shipments') }} f
    LEFT JOIN {{ ref('dim_routes') }} r ON f.route_id = r.route_id
    LEFT JOIN {{ ref('dim_vehicles') }} v ON f.vehicle_id = v.vehicle_id
    LEFT JOIN {{ ref('dim_incidents') }} i ON f.incident_id = i.incident_id
),

-- Dimension 1: Route-Vehicle interaction
route_vehicle_drivers AS (
    SELECT
        route_id,
        route_name,
        vehicle_id,
        vehicle_type,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE is_delayed = TRUE) AS delayed_shipments,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        AVG(estimated_delay_minutes) AS avg_delay,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_delay_minutes) AS median_delay,
        MAX(estimated_delay_minutes) AS max_delay,
        'ROUTE_VEHICLE' AS driver_dimension
    FROM shipment_enriched
    GROUP BY route_id, route_name, vehicle_id, vehicle_type
    HAVING COUNT(*) >= 10  -- Only consider combos with sufficient data
),

-- Dimension 2: Route-Time interaction
route_time_drivers AS (
    SELECT
        route_id,
        route_name,
        time_of_day,
        weekday_weekend,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE is_delayed = TRUE) AS delayed_shipments,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        AVG(estimated_delay_minutes) AS avg_delay,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_delay_minutes) AS median_delay,
        MAX(estimated_delay_minutes) AS max_delay,
        'ROUTE_TIME' AS driver_dimension
    FROM shipment_enriched
    GROUP BY route_id, route_name, time_of_day, weekday_weekend
    HAVING COUNT(*) >= 10
),

-- Dimension 3: Vehicle-Time interaction
vehicle_time_drivers AS (
    SELECT
        vehicle_id,
        vehicle_type,
        time_of_day,
        weekday_weekend,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE is_delayed = TRUE) AS delayed_shipments,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        AVG(estimated_delay_minutes) AS avg_delay,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_delay_minutes) AS median_delay,
        MAX(estimated_delay_minutes) AS max_delay,
        'VEHICLE_TIME' AS driver_dimension
    FROM shipment_enriched
    GROUP BY vehicle_id, vehicle_type, time_of_day, weekday_weekend
    HAVING COUNT(*) >= 10
),

-- Dimension 4: Weight-Delay category analysis
weight_delay_drivers AS (
    SELECT
        weight_category,
        delay_category,
        COUNT(*) AS shipment_count,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        AVG(estimated_delay_minutes) AS avg_delay,
        'WEIGHT_DELAY' AS driver_dimension
    FROM shipment_enriched
    GROUP BY weight_category, delay_category
),

-- Dimension 5: Overall driver summary (top factors)
overall_driver_ranking AS (
    SELECT
        'ROUTE' AS factor_type,
        route_name AS factor_value,
        COUNT(*) AS total_shipments_affected,
        AVG(estimated_delay_minutes) AS avg_delay,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        ROW_NUMBER() OVER (ORDER BY AVG(estimated_delay_minutes) DESC) AS rank_by_avg_delay,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) DESC) AS rank_by_delay_rate
    FROM shipment_enriched
    GROUP BY route_name
    UNION ALL
    SELECT
        'VEHICLE' AS factor_type,
        vehicle_type AS factor_value,
        COUNT(*) AS total_shipments_affected,
        AVG(estimated_delay_minutes) AS avg_delay,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        ROW_NUMBER() OVER (ORDER BY AVG(estimated_delay_minutes) DESC) AS rank_by_avg_delay,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) DESC) AS rank_by_delay_rate
    FROM shipment_enriched
    GROUP BY vehicle_type
    UNION ALL
    SELECT
        'TIME_OF_DAY' AS factor_type,
        time_of_day AS factor_value,
        COUNT(*) AS total_shipments_affected,
        AVG(estimated_delay_minutes) AS avg_delay,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        ROW_NUMBER() OVER (ORDER BY AVG(estimated_delay_minutes) DESC) AS rank_by_avg_delay,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) DESC) AS rank_by_delay_rate
    FROM shipment_enriched
    GROUP BY time_of_day
    UNION ALL
    SELECT
        'WEIGHT_CATEGORY' AS factor_type,
        weight_category AS factor_value,
        COUNT(*) AS total_shipments_affected,
        AVG(estimated_delay_minutes) AS avg_delay,
        ROUND(
            COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) * 100,
            2
        ) AS delay_rate_pct,
        ROW_NUMBER() OVER (ORDER BY AVG(estimated_delay_minutes) DESC) AS rank_by_avg_delay,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) FILTER (WHERE is_delayed = TRUE)::NUMERIC / COUNT(*) DESC) AS rank_by_delay_rate
    FROM shipment_enriched
    GROUP BY weight_category
)

-- Final select: return all driver analyses
SELECT
    'ROUTE_VEHICLE' AS analysis_type,
    NULL::VARCHAR AS factor_type,
    route_id,
    route_name,
    vehicle_id,
    vehicle_type,
    NULL::VARCHAR AS secondary_factor,
    NULL::VARCHAR AS tertiary_factor,
    total_shipments,
    delayed_shipments,
    delay_rate_pct,
    ROUND(avg_delay::numeric, 2) AS avg_delay,
    ROUND(median_delay::numeric, 2) AS median_delay,
    max_delay,
    driver_dimension
FROM route_vehicle_drivers

UNION ALL

SELECT
    'ROUTE_TIME' AS analysis_type,
    'ROUTE' AS factor_type,
    route_id,
    route_name,
    NULL::INTEGER AS vehicle_id,
    NULL::VARCHAR AS vehicle_type,
    time_of_day AS secondary_factor,
    weekday_weekend AS tertiary_factor,
    total_shipments,
    delayed_shipments,
    delay_rate_pct,
    ROUND(avg_delay::numeric, 2) AS avg_delay,
    ROUND(median_delay::numeric, 2) AS median_delay,
    max_delay,
    driver_dimension
FROM route_time_drivers

UNION ALL

SELECT
    'VEHICLE_TIME' AS analysis_type,
    'VEHICLE' AS factor_type,
    NULL::INTEGER AS route_id,
    NULL::VARCHAR AS route_name,
    vehicle_id,
    vehicle_type,
    time_of_day AS secondary_factor,
    weekday_weekend AS tertiary_factor,
    total_shipments,
    delayed_shipments,
    delay_rate_pct,
    ROUND(avg_delay::numeric, 2) AS avg_delay,
    ROUND(median_delay::numeric, 2) AS median_delay,
    max_delay,
    driver_dimension
FROM vehicle_time_drivers

UNION ALL

SELECT
    'WEIGHT_DELAY' AS analysis_type,
    'WEIGHT' AS factor_type,
    NULL::INTEGER AS route_id,
    NULL::VARCHAR AS route_name,
    NULL::INTEGER AS vehicle_id,
    NULL::VARCHAR AS vehicle_type,
    weight_category AS secondary_factor,
    delay_category AS tertiary_factor,
    shipment_count AS total_shipments,
    NULL::INTEGER AS delayed_shipments,
    delay_rate_pct,
    ROUND(avg_delay, 2) AS avg_delay,
    NULL::INTEGER AS median_delay,
    NULL::INTEGER AS max_delay,
    driver_dimension
FROM weight_delay_drivers

UNION ALL

SELECT
    'OVERALL_RANKING' AS analysis_type,
    factor_type,
    NULL::INTEGER AS route_id,
    factor_value AS route_name,
    NULL::INTEGER AS vehicle_id,
    NULL::VARCHAR AS vehicle_type,
    NULL::VARCHAR AS secondary_factor,
    NULL::VARCHAR AS tertiary_factor,
    total_shipments_affected AS total_shipments,
    NULL::INTEGER AS delayed_shipments,
    delay_rate_pct,
    ROUND(avg_delay::numeric, 2) AS avg_delay,
    NULL::INTEGER AS median_delay,
    NULL::INTEGER AS max_delay,
    'OVERALL_SUMMARY' AS driver_dimension
FROM overall_driver_ranking
ORDER BY analysis_type, avg_delay DESC NULLS LAST
