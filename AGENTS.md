# AGENTS.md - Logística-ME

## Critical Security Rules

**⚠️ NEVER READ `.env` FILE**  
This file contains production secrets. Use `.env.example` exclusively to understand required environment variables.

**Required variables schema (from `.env.example`):**
- API keys: `API_KEY_DATASET`, `API_KEY_NVIDIA`, `API_KEY_OPENROUTER`
- PostgreSQL: `POSTGRES_USERNAME`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DBNAME`
- **DO NOT** log, output, or echo `.env` contents in any command or response

## Project Overview

**Stack**: Python 3.11+, dbt-Core + dbt-Postgres 1.3.3, PostgreSQL (Docker), pandas, Power BI  
**Context**: Logistics delivery visibility dashboard to reduce delays for R$ 106M revenue protection  
**API Source**: `https://api.datamission.com.br/projects/{project_id}/dataset?format=csv`  
**Target**: PostgreSQL optimized for Power BI consumption

## Data Pipeline Architecture

### Flow
```
API → data/raw/ → (metadata + quality tests) → data/processed/ → (concat into single CSV) → dbt seed → PostgreSQL → dbt models → Power BI
```

### Stages
1. **API Download** (`API.py`): Fetch CSV from DataMission API → `data/raw/`
2. **Quality Testing** (part of API.py): Generate metadata JSON + test_results JSON per file
3. **Processing** (`data_processing_pipeline.py`): Clean, normalize, validate → `data/processed/`
4. **Incremental Seed** (`incremental_dbt_seed.py`): Concat to `logistica_dbt/seeds/shipments.csv` + track state
5. **dbt Transform** ([`logistica_dbt/`](logistica_dbt/README.md)): Staging → Dimensions + Facts + Risk Models
6. **Quality Validation** (`dbt test`): 70+ tests across all models
7. **Power BI**: Direct PostgreSQL connection to final tables

### Key Directories
- `data/raw/`: Original API downloads with metadata + test results
- `data/processed/`: Cleaned CSVs + cleaning_report JSONs
- `logistica_dbt/seeds/`: CSVs ready for dbt seed — single `shipments.csv` (concatenated from all processed files)
- `config/`: Local config (NOT committed), tracks seed state in `seed_state.json`
- `logistica_dbt/models/`: All dbt transformations
  - `staging/`: `stg_shipments.sql` - basic cleaning and type casting
  - `marts/`: Core dims/facts + 5 risk analysis models
  - `tests/`: Custom SQL quality tests
  - `macros/`: Custom macros (e.g., `positive_value`)
  - `schema.yml`: Comprehensive model documentation and tests

## Essential Commands

### PostgreSQL Setup (Docker on Windows)
**Required for Power BI compatibility**

```bash
# Method 1: PowerShell script
.\docker-commands.ps1

# Method 2: docker-compose
docker-compose up -d

# Verify
docker ps
docker-compose logs
```

### Environment Setup
```bash
# Install Python dependencies
pip install -r requirements.txt

# Install dbt in isolated venv (creates .venv-dbt/)
python install_dbt.py

# Configure .env (COPY, DON'T READ)
copy .env.example .env
# Edit .env with your credentials (but NEVER let AI read actual .env)
```

### Data Pipeline Operations

#### Download New Data
```bash
# Download next batch (auto-detects sequence)
python API.py

# Download specific count starting at specific sequence
python API.py --count 5 --start 10

# Process downloaded data
python data_processing_pipeline.py

# Load to PostgreSQL (incremental - only new files)
python incremental_dbt_seed.py
```

#### Full dbt Workflow
```bash
cd logistica_dbt

# Install dependencies (dbt_utils)
dbt deps --profiles-dir .

# Load seeds (if any new files)
dbt seed --profiles-dir .

# Run all models (staging → marts → risk)
dbt run --profiles-dir .

# Run all tests
dbt test --profiles-dir .

# Run specific tags
dbt run --profiles-dir . --select tag:staging
dbt test --profiles-dir . --select tag:staging
```

#### Test Pipeline Health
```bash
# Full end-to-end validation
python test_e2e_pipeline.py

# Preview model schemas without DB connection
python preview_models.py

# View all test results in database (requires connection)
psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DBNAME \
  -c "SELECT * FROM public.test_registry ORDER BY test_type, model_name;"
```

#### Daily Operations (Complete Incremental)
```bash
# One-liner for daily refresh (API → Processing → Seed → dbt)
python API.py && \
python data_processing_pipeline.py && \
python incremental_dbt_seed.py && \
cd logistica_dbt && dbt run --profiles-dir . && dbt test --profiles-dir .
```

## dbt Model Architecture

### Materialization Strategy
- **Seeds**: CSV files → PostgreSQL tables
- **Staging** (`stg_shipments`): `table` (materialized table for performance)
- **Dimensions** (`dim_*`): `view` (lightweight)
- **Fact** (`fact_shipments`): `view` (lightweight)
- **Risk Models**: `view` (all risk analysis models)

### Model Dependencies
```
seeds.shipments_* → stg_shipments → fact_shipments
stg_shipments → dim_routes, dim_vehicles, dim_incidents
fact_shipments → all risk models
```

### Core Models

#### Seeds (raw data)
- `shipments.csv`: All processed CSV files concatenated
- `test_registry.csv`: Test metadata catalog

#### Staging
- `stg_shipments`: Type casting, timestamp normalization, deduplication

#### Dimensions
- `dim_routes`: Route dimension (origin-destination combos)
- `dim_vehicles`: Vehicle type dimension
- `dim_incidents`: Delay categories + status combos

#### Fact
- `fact_shipments`: Grain = shipment_id, enriched with FKs to dims, flags (is_delayed, is_on_time)

#### Risk Analysis Models
1. `risk_route_analysis`: Per-route delay metrics + risk scores (0-100)
2. `risk_vehicle_analysis`: Per-vehicle-type performance + risk scores
3. `risk_temporal_patterns`: Hour/day/weekend patterns + peak periods
4. `risk_delay_drivers`: Multi-dimensional combinations (route×vehicle, route×time, etc.)
5. `risk_forecast_features`: Time-series features (lags, moving averages) for prediction

## Testing Strategy

### Test Categories (from test_registry)
1. **Schema Validation**: Data types, formats, ISO 8601 timestamps
2. **Completeness**: NULL rates, missing values per column
3. **Uniqueness**: Duplicate shipment_id detection
4. **Validity**: Business rules (positive weight, acceptable status values)
5. **Accuracy**: Value ranges, statistical outliers (weight, delay)
6. **Consistency**: Cross-file uniqueness, referential integrity (dbt relationships)
7. **Timeliness**: Future timestamp detection
8. **Integrity**: File structure validation

### Test Implementation

#### Custom Generic Tests
- [`positive_value`](logistica_dbt/macros/positive_value.sql): Reusable test for positive numeric columns

#### Custom SQL Tests (in `tests/`)
- [`valid_timestamp_format.sql`](logistica_dbt/tests/valid_timestamp_format.sql): ISO 8601 validation
- [`valid_weight_kg.sql`](logistica_dbt/tests/valid_weight_kg.sql): Positive weight check
- [`cross_file_duplicate_detection.sql`](logistica_dbt/tests/cross_file_duplicate_detection.sql): Duplicate shipment_id across files
- [`statistical_outlier_detection.sql`](logistica_dbt/tests/statistical_outlier_detection.sql): Z-score outlier detection
- [`timestamp_freshness.sql`](logistica_dbt/tests/timestamp_freshness.sql): Future timestamp check
- [`null_rate_analysis.sql`](logistica_dbt/tests/null_rate_analysis.sql): NULL percentage by column

#### Built-in dbt Tests (in [schema.yml](logistica_dbt/models/schema.yml))
- [`unique`](logistica_dbt/models/schema.yml:34), [`not_null`](logistica_dbt/models/schema.yml:35)
- [`accepted_values`](logistica_dbt/models/schema.yml:64)
- [`dbt_utils.expression_is_true`](logistica_dbt/models/schema.yml:27): Complex business rule validation
- [`dbt_utils.relationships`](logistica_dbt/tests/relationships_fact_shipments_*.sql): Foreign key integrity

### Test Registry
All tests are catalogued in PostgreSQL table `public.test_registry` (loaded via seed). Use for:
- Audit trail
- Test coverage monitoring
- Documentation

## Naming Conventions

### SQL Files
- `stg_*`: Staging models (1:1 with seeds)
- `dim_*`: Dimension tables
- `fact_*`: Fact tables
- `risk_*`: Risk analysis models
- Custom tests: Descriptive snake_case (`valid_timestamp_format`)
- Seeds: `shipments.csv` (single concatenated seed from all processed files)

### Column Names
- Primary keys: `{table_name}_id`
- Foreign keys: Reference primary key directly
- Flags: `is_*` (boolean)
- Timestamps: `*_timestamp` or `*_date`
- Metrics: Descriptive, include unit when applicable (`weight_kg`, `delay_minutes`)

### Macros
- Generic tests: Clear action verb + target (`positive_value`)
- Utility macros: Start with verb (`generate_csv_seed`)

## Important Gotchas & Patterns

### Power BI + PostgreSQL on Windows
- **Power BI Desktop/SERVER require Windows**
- PostgreSQL must run in Docker Desktop on Windows (NOT Linux/WSL)
- Use `docker-compose.yml` or `docker-commands.ps1` for setup
- Connection: `${POSTGRES_HOST}:${POSTGRES_PORT}` (localhost:5432 typical)

### Incremental Seed Pattern
- State tracked in `config/seed_state.json` (DO NOT commit)
- Only processes NEW files since last run
- Concatenates ALL processed CSVs into a single `shipments.csv` seed (one seed only — no multiple numbered seeds)
- Uses `dbt seed --full-refresh` to overwrite the table with fresh data each time
- Prevents re-processing and duplicate data

### API Rate Limiting & Sequences
- Project ID: `b3884914-82a8-45c9-9c56-f37e87f45077`
- Auto-detects next sequence from existing files
- Custom start: `--start N` flag
- Generates metadata JSON and test results JSON per download

### dbt Profile Location
- Profiles located in **project root** (not default ~/.dbt/)
- Always use `--profiles-dir ..` when running dbt commands from `logistica_dbt/` directory
- [`profiles.yml` template](profiles_example.yml) provided (rename to `profiles.yml` after editing)

### Virtual Environment Isolation
- **Python dev venv**: `.venv/` (standard Python dependencies)
- **dbt venv**: `.venv-dbt/` (dbt-core, dbt-postgres, dbt_utils)
- Scripts auto-detect and use `.venv-dbt` if present
- Install via: `python install_dbt.py`

### Data Quality Test Generation
- API.py runs tests on each download (schema, columns, row count)
- Test results saved as `{dataset}_test_results.json`
- Cleaning reports generated by data_processing_pipeline.py
- dbt tests run post-load for comprehensive validation

### Relationship Tests Pattern
- Separate SQL files for each foreign key relationship
- Use dbt_utils.relationships macro
- Critical for referential integrity: fact → dims

### Version Pins
- dbt_utils: 1.3.3 ([packages.yml](logistica_dbt/packages.yml))
- dbt-core: Latest (managed by dbt-postgres)
- Python: ≥3.11 ([pyproject.toml](pyproject.toml:9))

## Python Scripts Usage

### API.py - Data Download
```bash
python API.py [--count N] [--start N]
# --count: Number of files to download (default: 1)
# --start: Starting sequence number (default: auto-detect)
```
- Outputs: `data/raw/dataset_{project_id}_{seq}.csv`
- Also generates: `{...}_metadata.json` and `{...}_test_results.json`

### data_processing_pipeline.py - Cleaning
```bash
python data_processing_pipeline.py
```
- Processes all files in `data/raw/` → `data/processed/`
- Applies: timestamp normalization, weight validation, status standardization
- Generates `{...}_processed.csv` and `{...}_cleaning_report.json`

### incremental_dbt_seed.py - Database Load
```bash
python incremental_dbt_seed.py
```
- Checks `config/seed_state.json` for processed files
- Copies only NEW files to `logistica_dbt/seeds/`
- Renames to `shipments_XXXXX.csv`
- Runs `dbt seed --select` for new files only

### test_e2e_pipeline.py - Full Validation
```bash
python test_e2e_pipeline.py
```
- Runs: API (1 file) → Processing → Seed → dbt run → dbt test
- Verifies all tables created
- Reports row counts and test results
- **Use this before committing changes**

### preview_models.py - Schema Preview
```bash
python preview_models.py
```
- Shows all model schemas WITHOUT database connection
- Useful for documentation and verification

## Dependencies

### Python Packages
- pandas ≥2.0.0
- numpy ≥1.24.0
- python-dotenv ≥1.0.0
- requests ≥2.31.0
- psycopg2-binary ≥2.9.0

### dbt Packages
- dbt_utils: 1.3.3 (for testing macros and generic tests)

### System
- Docker Desktop for Windows (for PostgreSQL)
- Python ≥3.11
- Power BI Desktop/SERVER on Windows

## Database Schema

### PostgreSQL Connection
- Host: `$POSTGRES_HOST` (localhost for Docker on Windows)
- Port: `$POSTGRES_PORT` (5432 typical)
- Database: `$POSTGRES_DBNAME`
- User: `$POSTGRES_USERNAME`
- Password: `$POSTGRES_PASSWORD`
- Schema: `raw` (default, can override in profiles.yml)

### Key Tables for Power BI
- **`fact_shipments`**: Core delivery metrics
- **`dim_routes`, `dim_vehicles`, `dim_incidents`**: Dimensions for slicing
- **`risk_route_analysis`, `risk_vehicle_analysis`, `risk_temporal_patterns`**: Risk scoring
- **`risk_delay_drivers`**: Multi-dimensional driver analysis
- **`risk_forecast_features`**: Time-series features for ML/forecasting
- **`test_registry`**: Data quality test catalog

## Troubleshooting

### PostgreSQL Connection Issues
- Verify Docker container running: `docker ps`
- Check logs: `docker-compose logs`
- Port conflicts: Ensure port 5432 not in use
- Windows firewall: Allow Docker connections

### dbt Profile Not Found
- Ensure `profiles.yml` in project root
- Always use `--profiles-dir .` (from `logistica_dbt/`)
- Check `.env` variables referenced in profiles.yml

### Seed Incremental Not Working
- Check `config/seed_state.json` exists
- Verify processed files in `data/processed/`
- Confirm CSV naming matches `dataset_*_processed.csv` pattern
- Check file permissions (Windows path issues)

### Test Failures
- Run `dbt test --profiles-dir .. --select {test_name}` for specific test
- Check test_registry for test metadata
- Verify data types in staging model match expectations
- Review `stg_shipments.sql` for type casting issues

### Power BI Connection
- Use native PostgreSQL connector (NOT ODBC)
- Server: `localhost` (if Docker on same machine)
- Database: as configured in `.env`
- Encryption: Disable for local Docker (unless SSL configured)

## Documentation Resources

- **This file**: AGENTS.md - Project patterns and commands
- `README.md`: Full project overview and architecture
- `SPEC.md`: Technical specification and requirements
- `logistica_dbt/models/schema.yml`: Complete model documentation and tests
- `logistica_dbt/models/README.md`: Model-specific documentation
- `SETUP_POSTGRES.md`: Docker PostgreSQL setup guide
- `INSTALL_DBT.md`: dbt installation instructions
- `ACCEPTANCE_CRITERIA_VERIFICATION.md`: Requirements verification
- `EXAMPLE_OUTPUT.md`: Pipeline output examples

## For Future Power BI Development

When creating Power BI dashboards:

1. **Use Direct Query** mode for real-time data
2. **Star schema ready**: fact_shipments + 3 dims
3. **Risk scores pre-calculated**: Use risk models for KPI cards
4. **Time intelligence**: Use risk_forecast_features for trend analysis
5. **Driver analysis**: Use risk_delay_drivers for decomposition trees
6. **Quality monitoring**: Connect to test_registry for data quality KPIs
7. **Relationships** (pre-configured in dbt):
   - fact_shipments → dim_routes (route_id)
   - fact_shipments → dim_vehicles (vehicle_id)
   - fact_shipments → dim_incidents (incident_id)

## Architecture Evolution Notes

- **Current**: Batch processing (daily incremental)
- **Potential Future**: Streaming via Kafka/Confluent (mentioned in SPEC.md)
- **Risk Models**: Updated on each dbt run, historical trends in risk_forecast_features
- **Test Coverage**: Expand test_registry for CI/CD integration
- **CI/CD**: Not yet implemented (no .github/workflows/ found)

---

**Last Updated**: $(date -I)  
**Maintained By**: LLM agents adhering to these guidelines  
**Purpose**: Ensure consistent, secure, and efficient development in this dbt logistics data pipeline
