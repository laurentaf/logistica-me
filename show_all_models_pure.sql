-- Script: Mostra primeira linha de cada modelo dbt
-- Execute no PostgreSQL diretamente (psql ou DBeaver)
-- Substitua 'public' pelo seu schema se diferente (ex: 'raw')

\echo '================================================================================'
\echo 'PRIMEIRA LINHA DE CADA TABELA - PROJETO LOGISTICA-ME'
\echo '================================================================================'

-- Staging
\echo ''
\echo '📊 stg_shipments'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.stg_shipments LIMIT 1;

-- Dimensões
\echo ''
\echo '📊 dim_routes'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.dim_routes LIMIT 1;

\echo ''
\echo '📊 dim_vehicles'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.dim_vehicles LIMIT 1;

\echo ''
\echo '📊 dim_incidents'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.dim_incidents LIMIT 1;

-- Fato
\echo ''
\echo '📊 fact_shipments'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.fact_shipments LIMIT 1;

-- Risk Models
\echo ''
\echo '📊 risk_route_analysis'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.risk_route_analysis LIMIT 1;

\echo ''
\echo '📊 risk_vehicle_analysis'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.risk_vehicle_analysis LIMIT 1;

\echo ''
\echo '📊 risk_temporal_patterns'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.risk_temporal_patterns LIMIT 1;

\echo ''
\echo '📊 risk_delay_drivers'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.risk_delay_drivers LIMIT 1;

\echo ''
\echo '📊 risk_forecast_features'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.risk_forecast_features LIMIT 1;

-- Test Registry
\echo ''
\echo '📊 test_registry'
\echo '-------------------------------------------------------------------'
SELECT * FROM public.test_registry LIMIT 5;

\echo ''
\echo '================================================================================'
\echo '✅ Exibição concluída'
\echo '================================================================================'
