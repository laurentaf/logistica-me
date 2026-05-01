{{ config(materialized='table', tags=['risk', 'marts', 'forecast', 'features']) }}

-- Forecast Feature Table
-- Provides aggregated features for delay forecasting and trend analysis
-- Granularity: Date x Route x Vehicle x Time Bucket
-- Features suitable for Power BI trend analysis and ML forecasting

WITH daily_aggregates AS (
    SELECT
        DATE(f.event_timestamp) AS event_date,
        f.route_id,
        f.vehicle_id,
        CASE
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 6 AND 10 THEN 'MORNING_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 11 AND 14 THEN 'MIDDAY'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 15 AND 18 THEN 'AFTERNOON_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 19 AND 22 THEN 'EVENING'
            ELSE 'NIGHT'
        END AS time_of_day_bucket,
        CASE WHEN EXTRACT(DOW FROM f.event_timestamp) IN (0, 6) THEN 'WEEKEND' ELSE 'WEEKDAY' END AS weekday_weekend,
        -- Weight category for the day (average)
        AVG(f.weight_kg) AS avg_weight_kg,
        COUNT(*) AS total_shipments,
        COUNT(*) FILTER (WHERE f.is_delayed = TRUE) AS delayed_shipments,
        COUNT(*) FILTER (WHERE f.is_on_time = TRUE) AS on_time_shipments,
        AVG(f.estimated_delay_minutes) AS avg_delay_minutes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS median_delay_minutes,
        MAX(f.estimated_delay_minutes) AS max_delay_minutes,
        STDDEV(f.estimated_delay_minutes) AS stddev_delay_minutes,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q1_delay,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY f.estimated_delay_minutes) AS q3_delay,
        -- Percent metrics
        ROUND(
            COUNT(*) FILTER (WHERE f.is_delayed = TRUE)::NUMERIC / GREATEST(COUNT(*), 1) * 100,
            2
        ) AS delay_rate_pct,
        -- Heavy shipment percentage
        ROUND(
            COUNT(*) FILTER (WHERE f.weight_kg > 1000)::NUMERIC / GREATEST(COUNT(*), 1) * 100,
            2
        ) AS heavy_shipment_pct,
        -- Incident distribution
        MODE() WITHIN GROUP (ORDER BY i.delay_category) AS most_common_delay_category,
        MODE() WITHIN GROUP (ORDER BY v.vehicle_type) AS most_common_vehicle_type
    FROM {{ ref('fact_shipments') }} f
    LEFT JOIN {{ ref('dim_routes') }} r ON f.route_id = r.route_id
    LEFT JOIN {{ ref('dim_vehicles') }} v ON f.vehicle_id = v.vehicle_id
    LEFT JOIN {{ ref('dim_incidents') }} i ON f.incident_id = i.incident_id
    GROUP BY
        DATE(f.event_timestamp),
        f.route_id,
        f.vehicle_id,
        CASE
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 6 AND 10 THEN 'MORNING_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 11 AND 14 THEN 'MIDDAY'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 15 AND 18 THEN 'AFTERNOON_RUSH'
            WHEN EXTRACT(HOUR FROM f.event_timestamp) BETWEEN 19 AND 22 THEN 'EVENING'
            ELSE 'NIGHT'
        END,
        CASE WHEN EXTRACT(DOW FROM f.event_timestamp) IN (0, 6) THEN 'WEEKEND' ELSE 'WEEKDAY' END
),

-- Enrich with route risk scores and vehicle risk scores
with_risk_scores AS (
    SELECT
        d.*,
        r.risk_score AS route_risk_score,
        r.risk_category AS route_risk_category,
        v.risk_score AS vehicle_risk_score,
        v.risk_category AS vehicle_risk_category,
        -- Combined risk indicator
        CASE
            WHEN r.risk_score >= 70 OR v.risk_score >= 70 THEN 'HIGH'
            WHEN r.risk_score >= 40 OR v.risk_score >= 40 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS combined_risk_level,
        -- Lag features for time series (previous day same bucket)
        LAG(d.total_shipments, 1) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
        ) AS prev_day_shipments,
        LAG(d.avg_delay_minutes, 1) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
        ) AS prev_day_avg_delay,
        LAG(d.delay_rate_pct, 1) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
        ) AS prev_day_delay_rate,
        -- 7-day moving average (using window functions)
        AVG(d.avg_delay_minutes) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7day_delay,
        AVG(d.delay_rate_pct) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7day_delay_rate,
        -- Trend indicators
        (d.avg_delay_minutes - LAG(d.avg_delay_minutes, 1) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
        )) AS delay_change_from_prev_day,
        (d.delay_rate_pct - LAG(d.delay_rate_pct, 1) OVER (
            PARTITION BY d.route_id, d.vehicle_id, d.time_of_day_bucket, d.weekday_weekend
            ORDER BY d.event_date
        )) AS delay_rate_change_from_prev_day
    FROM daily_aggregates d
    LEFT JOIN {{ ref('risk_route_analysis') }} r ON d.route_id = r.route_id
    LEFT JOIN {{ ref('risk_vehicle_analysis') }} v ON d.vehicle_id = v.vehicle_id
)

SELECT
    event_date,
    route_id,
    vehicle_id,
    time_of_day_bucket,
    weekday_weekend,
    avg_weight_kg,
    total_shipments,
    delayed_shipments,
    on_time_shipments,
    ROUND(avg_delay_minutes, 2) AS avg_delay_minutes,
    ROUND(median_delay_minutes, 2) AS median_delay_minutes,
    max_delay_minutes,
    ROUND(stddev_delay_minutes, 2) AS stddev_delay_minutes,
    q1_delay,
    q3_delay,
    delay_rate_pct,
    heavy_shipment_pct,
    most_common_delay_category,
    most_common_vehicle_type,
    route_risk_score,
    route_risk_category,
    vehicle_risk_score,
    vehicle_risk_category,
    combined_risk_level,
    prev_day_shipments,
    prev_day_avg_delay,
    prev_day_delay_rate,
    ROUND(moving_avg_7day_delay, 2) AS moving_avg_7day_delay,
    ROUND(moving_avg_7day_delay_rate, 2) AS moving_avg_7day_delay_rate,
    ROUND(delay_change_from_prev_day, 2) AS delay_change_from_prev_day,
    ROUND(delay_rate_change_from_prev_day, 2) AS delay_rate_change_from_prev_day
FROM with_risk_scores
ORDER BY event_date DESC, route_id, vehicle_id, time_of_day_bucket
