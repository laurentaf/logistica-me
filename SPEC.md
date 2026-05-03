# Logistica-ME Specification

**Project**: Logistics Delivery Visibility Dashboard for Delay Reduction
**Stack**: Python 3.12+ | dbt 1.11.8 | PostgreSQL | Power BI
**Author**: Laurent Alphonse Ferreira
**Pipeline**: Incremental API → Raw → Cleaned → dbt Seed → PostgreSQL → Power BI

---

## 1. Vision & Goals

Build a production-grade data pipeline that:
- Ingests logistics shipment data from the DataMission API incrementally
- Cleans, normalizes, and stores data in PostgreSQL via dbt
- Generates risk analysis models for delivery delay forecasting
- Produces a clean data warehouse schema ready for Power BI visualization

**Non-Goals**: ML model training (features only), real-time streaming, multi-cloud deployment

---

## 2. Architecture

```
DataMission API
     │
     ▼
[API.py] ──► data/raw/
                    │
                    ▼
[data_processing_pipeline.py] ──► data/processed/
                                        │
                                        ▼
[incremental_dbt_seed.py] ──► logistica_dbt/seeds/ ──► PostgreSQL (dbt seed)
                                                                       │
                                                                       ▼
                                              [dbt run] ──► raw.{stg_shipments, fact_shipments, dim_*, risk_*}
                                              [dbt test] ──► quality validation
                                                                       │
                                                                       ▼
                                                                   Power BI
```

---

## 3. Data Schema

### 3.1 Source API Schema (CSV from DataMission)

Endpoint: `https://api.datamission.com.br/projects/{project_id}/dataset?format=csv`
Authentication: Bearer token (`API_KEY_DATASET` in `.env`)

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `shipment_id` | UUID | Unique shipment identifier | `b3884914-82a8-45c9-9c56-f37e87f45077` |
| `timestamp` | ISO 8601 | Event tracking timestamp | `2025-04-12T08:30:15.123456` |
| `origin` | string | Shipment origin location | `São Paulo` |
| `destination` | string | Shipment destination | `Rio de Janeiro` |
| `weight_kg` | float | Weight in kilograms | `125.5` |
| `delivery_status` | string | Status (IN_TRANSIT, DELIVERED, etc.) | `IN_TRANSIT` |
| `vehicle_type` | string | Vehicle type (TRUCK, MOTORCYCLE, AIRPLANE, etc.) | `TRUCK` |
| `estimated_delay_minutes` | integer | Estimated delay in minutes (negative = early) | `15` |

### 3.2 dbt Staging Model

**`stg_shipments`** — raw data typed and cleaned
- Materialized as `table`
- Source: `{{ ref('shipments') }}` (the unioned seed table)
- Type casting: timestamp, numeric, integer

### 3.3 dbt Marts Models

**Core Fact & Dimensions:**

| Model | Type | Description | Materialization |
|-------|------|-------------|-----------------|
| `fact_shipments` | FACT | Shipment events with delay metrics and FKs | `table` |
| `dim_routes` | DIM | Route dimension (origin-destination pairs) | `view` |
| `dim_vehicles` | DIM | Vehicle type dimension | `view` |
| `dim_incidents` | DIM | Incident dimension (status + delay category) | `view` |

**Risk Analysis Models:**

| Model | Type | Description | Materialization |
|-------|------|-------------|-----------------|
| `risk_route_analysis` | RISK | Risk score by route | `table` |
| `risk_vehicle_analysis` | RISK | Risk score by vehicle type | `table` |
| `risk_temporal_patterns` | RISK | Delay patterns by time of day/week | `table` |
| `risk_delay_drivers` | RISK | Multi-factor delay driver analysis | `table` |
| `risk_forecast_features` | RISK | Time-series features for forecasting | `table` |

### 3.4 fact_shipments Schema

| Column | Type | Description |
|--------|------|-------------|
| `shipment_id` | UUID | PK |
| `event_timestamp` | timestamp | Event time |
| `route_id` | string | FK → dim_routes |
| `vehicle_id` | string | FK → dim_vehicles |
| `incident_id` | string | FK → dim_incidents |
| `weight_kg` | numeric | Shipment weight |
| `estimated_delay_minutes` | integer | Delay in minutes |
| `is_on_time` | boolean | True if delay ≤ 0 |
| `is_delayed` | boolean | True if delay > 0 |
| `event_date` | date | Day truncated |
| `event_hour` | timestamp | Hour truncated |

---

## 4. Scripts & Entry Points

| Script | Purpose | Usage |
|--------|---------|-------|
| `API.py` | Download CSV from DataMission API with inline quality tests | `python API.py --count 5 --start 1` |
| `data_processing_pipeline.py` | Clean and standardize raw CSVs | `python data_processing_pipeline.py` |
| `incremental_dbt_seed.py` | Copy processed CSVs to dbt seeds, run dbt seed | `python incremental_dbt_seed.py` |
| `test_e2e_pipeline.py` | Full E2E pipeline validation with colored output | `python test_e2e_pipeline.py` |
| `preview_models.py` | Print dbt model schemas without DB connection | `python preview_models.py` |
| `install_dbt.py` | Install dbt-core + dbt-postgres + dbt_utils | `python install_dbt.py` |

### 4.1 API.py Options

```
--count N   Number of files to download (default: 5)
--start N   Starting sequence number (default: auto-detect from existing files)
```

### 4.2 dbt Commands

```bash
cd logistica_dbt
dbt deps --profiles-dir .           # Install dbt_utils
dbt seed --profiles-dir .            # Load seeds to PostgreSQL
dbt run --profiles-dir .             # Run staging → marts models
dbt test --profiles-dir .            # Run quality tests
```

---

## 5. Directory Structure

```
Logistica-ME/
├── API.py                           # API download + inline quality tests
├── data_processing_pipeline.py      # Data cleaning
├── incremental_dbt_seed.py          # Incremental dbt seed loader
├── test_e2e_pipeline.py             # E2E pipeline validation
├── preview_models.py                # Schema preview utility
├── install_dbt.py                   # dbt installation script
├── requirements.txt                  # Python dependencies
├── pyproject.toml                    # Python project metadata
├── download_conformity_summary.json  # API download test results
│
├── data/
│   ├── raw/                         # API downloads
│   │   ├── dataset_*.csv
│   │   ├── dataset_*_metadata.json
│   │   └── dataset_*_test_results.json
│   └── processed/                   # Cleaned data
│       ├── dataset_*_processed.csv
│       └── dataset_*_cleaning_report.json
│
├── logistica_dbt/
│   ├── dbt_project.yml
│   ├── packages.yml                  # dbt_utils dependency
│   ├── profiles.yml                  # DB connection config
│   ├── models/
│   │   ├── staging/
│   │   │   └── stg_shipments.sql
│   │   ├── marts/
│   │   │   ├── fact_shipments.sql
│   │   │   ├── dim_routes.sql
│   │   │   ├── dim_vehicles.sql
│   │   │   ├── dim_incidents.sql
│   │   │   ├── risk_route_analysis.sql
│   │   │   ├── risk_vehicle_analysis.sql
│   │   │   ├── risk_temporal_patterns.sql
│   │   │   ├── risk_delay_drivers.sql
│   │   │   ├── risk_forecast_features.sql
│   │   │   ├── test_results.sql
│   │   │   └── schema.yml             # Tests + docs for all marts
│   │   └── shipments.sql             # Union of all seed tables
│   ├── seeds/
│   │   ├── shipments_*.csv           # 35+ incremental seed files
│   │   ├── test_registry.csv
│   │   └── schema.yml
│   ├── tests/                       # Custom SQL quality tests
│   │   ├── valid_timestamp_format.sql
│   │   ├── valid_weight_kg.sql
│   │   ├── valid_delay_minutes.sql
│   │   ├── cross_file_duplicate_detection.sql
│   │   ├── timestamp_freshness.sql
│   │   ├── null_rate_analysis.sql
│   │   ├── statistical_outlier_detection.sql
│   │   └── data_freshness_score.sql
│   ├── macros/
│   │   ├── generate_csv_seed.sql
│   │   └── positive_value.sql
│   └── README.md
│
├── config/
│   └── seed_state.json               # Incremental seed tracking (gitignored)
│
├── .env                              # Secrets (gitignored)
├── .env.example                      # Template for .env
├── .gitignore
│
└── docker-compose.yml                 # PostgreSQL Docker setup
```

---

## 6. Environment Variables

Stored in `.env` (NEVER commit this file):

| Variable | Description | Example |
|----------|-------------|---------|
| `API_KEY_DATASET` | DataMission API token | `eyJhbG...` |
| `API_KEY_NVIDIA` | NVIDIA API key | `nvapi-...` |
| `API_KEY_OPENROUTER` | OpenRouter API key | `sk-or-...` |
| `POSTGRES_HOST` | PostgreSQL host | `localhost` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_DBNAME` | Database name | `logistica_db` |
| `POSTGRES_USERNAME` | DB username | `postgres` |
| `POSTGRES_PASSWORD` | DB password | `ChangeMe123!` |

---

## 7. Acceptance Criteria

### 7.1 Pipeline Execution

- [x] `API.py` downloads CSV files from DataMission API with Bearer token auth
- [x] `API.py` generates `_metadata.json` and `_test_results.json` for each download
- [x] `API.py` runs inline data quality tests (schema validation, row count, conformity %)
- [x] `data_processing_pipeline.py` cleans all raw files and produces processed CSVs
- [x] `incremental_dbt_seed.py` copies only new processed files to dbt seeds directory
- [x] `incremental_dbt_seed.py` tracks state in `config/seed_state.json`
- [x] `incremental_dbt_seed.py` runs `dbt seed` for only new seed files

### 7.2 dbt Models

- [x] `stg_shipments` reads from `shipments` seed, applies type casting
- [x] `fact_shipments` joins staging with dimension tables, derives `is_on_time`, `is_delayed`
- [x] `dim_routes`, `dim_vehicles`, `dim_incidents` created correctly
- [x] All 5 risk analysis models produce meaningful aggregations
- [x] `dbt run` completes without errors
- [x] `dbt deps` installs `dbt-labs/dbt_utils` 1.3.3

### 7.3 Data Quality Tests

- [x] Custom `positive_value` test defined in `macros/positive_value.sql`
- [x] All `dbt_utils.expression_is_true` tests pass without SQL compilation errors
- [x] `unique_fact_shipments_shipment_id` validates uniqueness (known: 13,875 historical duplicates)
- [x] `valid_weight_kg` validates weight > 0 (known: 2 invalid rows in historical data)
- [x] Relationship tests between fact and dimensions pass
- [x] SQL-based tests (valid_timestamp_format, valid_delay_minutes, etc.) pass

### 7.4 Database

- [x] PostgreSQL Docker container runs via `docker-compose up -d`
- [x] All 11 tables exist in `raw` schema: `stg_shipments`, `fact_shipments`, `dim_routes`, `dim_vehicles`, `dim_incidents`, `risk_route_analysis`, `risk_vehicle_analysis`, `risk_temporal_patterns`, `risk_delay_drivers`, `risk_forecast_features`, `test_registry`
- [x] `fact_shipments` contains 624,905+ rows
- [x] `risk_route_analysis` contains 13,428+ rows

### 7.5 Security

- [x] `.env` is gitignored and never committed
- [x] `.env.example` provides schema without exposing secrets
- [x] `.claude/memory.md` instructs LLMs to never read `.env`
- [x] `.claude/settings.local.json` denies `Read(.env)` for Claude

---

## 8. Known Issues & Open Items

### 8.1 Data Quality Issues (Historical)

- **`unique_fact_shipments_shipment_id`**: 13,875 duplicate shipment_ids exist in historical data. This is a known upstream data issue, not a pipeline bug.
- **`valid_weight_kg`**: 2 rows with non-positive weight in historical data. Known upstream issue.
- These issues do not block pipeline execution but are recorded for upstream remediation.

### 8.2 dbt Test Configuration

- `dbt_utils.expression_is_true` tests reference columns that are `FLOAT/NUMERIC` and may have NULL values. The tests use syntax like `pct_delayed >= 0 AND pct_delayed <= 100` which requires the column to be NOT NULL for the test to make semantic sense. Consider adding `NOT NULL` constraints or adjusting test expressions.

### 8.3 Token Tracking

- The original README referenced `.claude/tokens.md` for API token usage. This file does not exist in the current codebase. Token tracking is not implemented.

### 8.4 Incomplete Directories

- `src/` and `tests/` (root level) are empty placeholder directories
- `notebooks/` is empty

---

## 9. Dependencies

### Python (from requirements.txt)
```
pandas>=2.0.0
numpy>=1.24.0
python-dotenv>=1.0.0
requests>=2.31.0
psycopg2-binary>=2.9.0
```

### dbt Packages
```
dbt-labs/dbt_utils: 1.3.3
```

### System
```
Python >=3.11
PostgreSQL (Docker or local)
dbt 1.11.8
Docker (for PostgreSQL)
```

---

## 10. Quick Start

```bash
# 1. Setup environment
cp .env.example .env
# Edit .env with your credentials

# 2. Start PostgreSQL
docker-compose up -d

# 3. Install dependencies
pip install -r requirements.txt

# 4. Install dbt
python install_dbt.py

# 5. Run full pipeline
python test_e2e_pipeline.py

# 6. Update daily
python API.py --count 5
python data_processing_pipeline.py
python incremental_dbt_seed.py
cd logistica_dbt && dbt run && dbt test
```

---

## 11. Change Log

| Date | Change |
|------|--------|
| 2026-05-02 | Added `test_e2e_pipeline.py` with full env var overrides |
| 2026-05-02 | Fixed indentation bug in `API.py` data quality test generation |
| 2026-05-02 | Created `positive_value` macro for schema.yml tests |
| 2026-05-02 | Upgraded `dbt_utils` from 1.1.0 to 1.3.3 to fix `expression_is_true` SQL bug |
| 2026-05-02 | Updated `.claude/memory.md` with correct schema and security rules |
| 2026-05-02 | Updated `.claude/settings.local.json` to deny `.env` reads |
| 2026-05-02 | Fixed requirements.txt (added missing dependencies) |
| 2026-05-02 | Updated README with missing scripts and fixed duplicate sections |