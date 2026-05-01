-- Script: Mostra primeira linha de cada modelo dbt
-- Execute no PostgreSQL após dbt run

\echo '================================================================================'
\echo 'PRIMEIRA LINHA DE CADA TABELA - PROJETO LOGISTICA-ME'
\echo '================================================================================'

-- Staging
\echo ''
\echo '📊 stg_shipments'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.stg_shipments LIMIT 1;

-- Dimensões
\echo ''
\echo '📊 dim_routes'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.dim_routes LIMIT 1;

\echo ''
\echo '📊 dim_vehicles'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.dim_vehicles LIMIT 1;

\echo ''
\echo '📊 dim_incidents'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.dim_incidents LIMIT 1;

-- Fato
\echo ''
\echo '📊 fact_shipments'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.fact_shipments LIMIT 1;

-- Risk Models
\echo ''
\echo '📊 risk_route_analysis'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.risk_route_analysis LIMIT 1;

\echo ''
\echo '📊 risk_vehicle_analysis'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.risk_vehicle_analysis LIMIT 1;

\echo ''
\echo '📊 risk_temporal_patterns'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.risk_temporal_patterns LIMIT 1;

\echo ''
\echo '📊 risk_delay_drivers'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.risk_delay_drivers LIMIT 1;

\echo ''
\echo '📊 risk_forecast_features'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.risk_forecast_features LIMIT 1;

-- Test Registry
\echo ''
\echo '📊 test_registry'
\echo '-------------------------------------------------------------------'
SELECT * FROM {{ target.schema }}.test_registry LIMIT 5;

\echo ''
\echo '================================================================================'
\echo '✅ Exibição concluída'
\echo '================================================================================'
