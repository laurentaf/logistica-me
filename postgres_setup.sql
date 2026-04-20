-- PostgreSQL Database Setup for Logistica-ME Project
-- Run this script in PostgreSQL to create database and schemas

-- Create database (run as PostgreSQL superuser)
CREATE DATABASE logistica_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- Connect to the new database
\c logistica_db

-- Create schemas for different data layers
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS dbt_artifacts;

-- Grant permissions (adjust based on your security requirements)
GRANT ALL ON SCHEMA raw TO postgres;
GRANT ALL ON SCHEMA staging TO postgres;
GRANT ALL ON SCHEMA analytics TO postgres;
GRANT ALL ON SCHEMA dbt_artifacts TO postgres;

-- Create example user for dbt (optional)
-- CREATE USER dbt_user WITH PASSWORD 'dbt_password';
-- GRANT CONNECT ON DATABASE logistica_db TO dbt_user;
-- GRANT USAGE ON SCHEMA raw TO dbt_user;
-- GRANT USAGE ON SCHEMA staging TO dbt_user;
-- GRANT USAGE ON SCHEMA analytics TO dbt_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA raw TO dbt_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA staging TO dbt_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA analytics TO dbt_user;

-- Create tables for CSV import (dbt will handle this, but here's the structure)
CREATE TABLE IF NOT EXISTS raw.raw_logs_00001 (
    log_id UUID PRIMARY KEY,
    timestamp TIMESTAMP,
    ip_address VARCHAR(45),
    http_method VARCHAR(10),
    endpoint TEXT,
    status_code INTEGER,
    response_time_ms INTEGER,
    user_agent TEXT
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON raw.raw_logs_00001(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_endpoint ON raw.raw_logs_00001(endpoint);
CREATE INDEX IF NOT EXISTS idx_logs_status_code ON raw.raw_logs_00001(status_code);

-- View to see all tables
CREATE OR REPLACE VIEW raw.database_overview AS
SELECT 
    table_schema,
    table_name,
    pg_size_pretty(pg_total_relation_size('"' || table_schema || '"."' || table_name || '"')) AS size
FROM information_schema.tables
WHERE table_schema IN ('raw', 'staging', 'analytics')
ORDER BY table_schema, table_name;

-- Display database information
SELECT 
    current_database() AS database,
    current_user AS current_user,
    version() AS postgres_version;

-- Show schemas created
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name NOT LIKE 'pg_%' 
AND schema_name != 'information_schema'
ORDER BY schema_name;